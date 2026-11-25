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


GLYPHS = {"7": ["111", "001", "010", "010", "010"], "9": ["111", "101", "111", "001", "111"]}


def icon():
    """The 40 x 40 launcher icon: a pixel-art scoreboard. A rounded blue and red split (the app's
    two sides) with a white divider, a white ribbon on top and a 7 and a 9 in white with a navy
    outline. No anti-aliasing, so it stays crisp."""
    n = 40
    navy = (11, 37, 64, 255)
    white = (252, 252, 252, 255)
    blue = (46, 155, 255, 255)
    red = (229, 52, 58, 255)
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()

    def rounded(x0, y0, x1, y1, rad, fill):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                cx = min(max(x, x0 + rad), x1 - rad)
                cy = min(max(y, y0 + rad), y1 - rad)
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if d <= rad + 0.4:
                    px[x, y] = navy if d > rad - 0.6 else fill(x)

    def glyph(ch, x0, y0, s, col):
        for j, row in enumerate(GLYPHS[ch]):
            for i, bit in enumerate(row):
                if bit == "1":
                    for a in range(s):
                        for b in range(s):
                            px[x0 + i * s + a, y0 + j * s + b] = col

    rounded(3, 5, 36, 34, 5, lambda x: blue if x < 20 else red)
    for x in (19, 20):
        for y in range(7, 33):
            px[x, y] = white
    rounded(11, 3, 28, 9, 3, lambda x: white)
    for ch, x0 in (("7", 6), ("9", 24)):
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx or dy:
                    glyph(ch, x0 + dx, 13 + dy, 4, navy)
        glyph(ch, x0, 13, 4, white)
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
