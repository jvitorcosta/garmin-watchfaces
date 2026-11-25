"""Build Volley Score's fonts (volleyscore/resources/gen/): Bebas Neue (tools/fonts, OFL) as
anti-aliased white-on-transparent BMFont fonts. bebas_score is the big digits for the points,
bebas_label the ribbon and set-history text. Glyph cells are cropped to the cap height, so a font
centres the way the eye expects. Needs only Pillow: python tools/gen_volleyscore.py"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "tools", "fonts", "BebasNeue-Regular.ttf")
OUT = os.path.join(ROOT, "volleyscore", "resources", "gen")

FONTS = [("bebas_score", 128, "0123456789"),
         ("bebas_title", 100, "ABCDEFGHIJKLMNOPQRSTUVWXYZ "),
         ("bebas_label", 30, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -\u00b7+")]


def bmfont(name, size, chars):
    f = ImageFont.truetype(FONT, size)
    ascent, _ = f.getmetrics()
    # cap height: the top of a digit above the baseline (anchor "ls" = left, baseline)
    cap = -f.getbbox("0", anchor="ls")[1]
    h = cap
    cells = []
    for ch in chars:
        adv = int(round(f.getlength(ch)))
        g = Image.new("L", (max(adv, 1), h), 0)
        ImageDraw.Draw(g).text((0, h), ch, font=f, fill=255, anchor="ls")
        cells.append((ch, g, adv))
    page = Image.new("RGBA", (sum(g.width + 2 for _, g, _ in cells), h), (0, 0, 0, 0))
    rows, x = [], 0
    for ch, g, adv in cells:
        white = Image.new("RGBA", g.size, (255, 255, 255, 255))
        white.putalpha(g)
        page.paste(white, (x, 0))
        rows.append("char id=%d x=%d y=0 width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                    % (ord(ch), x, g.width, h, adv))
        x += g.width + 2
    text = ("info face=\"%s\" size=%d bold=0 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=1 aa=1 "
            "padding=0,0,0,0 spacing=1,1\n" % (name, size)
            + "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0\n" % (h, h, page.width, h)
            + "page id=0 file=\"%s.png\"\n" % name + "chars count=%d\n" % len(rows) + "\n".join(rows) + "\n")
    return text, page


def gen_xml():
    fonts = "\n".join('    <font id="%s" filename="%s.fnt" antialias="true"/>'
                      % ("".join(p.title() for p in name.split("_")), name) for name, _, _ in FONTS)
    return "<resources>\n<fonts>\n" + fonts + "\n</fonts>\n</resources>\n"


def icon():
    """The 40 x 40 launcher icon: a pixel-art beach volleyball. Three ball-sized circles shifted in
    three directions cut the ball into panels, painted white, yellow, blue and red (the beach ball
    look); a navy outline and seams, a shaded lower right and a small highlight. No anti-aliasing."""
    n = 40
    c = (n - 1) / 2.0
    r = 18.6
    navy = (11, 37, 64, 255)
    pal = {0: (252, 252, 252), 1: (255, 205, 40), 2: (46, 155, 255), 3: (229, 52, 58)}
    centres = [(-13.0, 2.0), (13.0, 2.0), (0.0, -15.0)]
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    for y in range(n):
        for x in range(n):
            dx, dy = x - c, y - c
            d = (dx * dx + dy * dy) ** 0.5
            if d > r:
                continue
            dist = [((dx - sx) ** 2 + (dy - sy) ** 2) ** 0.5 for sx, sy in centres]
            inside = [e < 19.0 for e in dist]
            key = {(0, 0, 0): 0, (1, 0, 0): 2, (0, 1, 0): 2, (0, 0, 1): 1, (1, 1, 0): 0,
                   (1, 0, 1): 3, (0, 1, 1): 3, (1, 1, 1): 1}[tuple(int(v) for v in inside)]
            rgb = pal[key]
            shade = dx * 0.6 + dy * 0.8
            if shade > 8:
                f = 0.84 if shade <= 14 else 0.7
                rgb = tuple(int(v * f) for v in rgb)
            col = rgb + (255,)
            if any(abs(e - 19.0) < 0.75 for e in dist):
                col = navy
            if (dx + 9) ** 2 + (dy + 9) ** 2 < 3:
                col = (255, 255, 255, 255)
            if d > r - 1.6:
                col = navy
            px[x, y] = col
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    icon().save(os.path.join(ROOT, "volleyscore", "resources", "drawables", "launcher_icon.png"))
    for name, size, chars in FONTS:
        text, page = bmfont(name, size, chars)
        page.save(os.path.join(OUT, name + ".png"))
        with open(os.path.join(OUT, name + ".fnt"), "w", encoding="utf-8") as f:
            f.write(text)
        print(name, page.size)
    with open(os.path.join(OUT, "gen.xml"), "w", encoding="utf-8") as f:
        f.write(gen_xml())


if __name__ == "__main__":
    main()
