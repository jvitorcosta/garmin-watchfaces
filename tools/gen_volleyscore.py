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
         ("bebas_label", 30, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -\u00b7")]


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


def main():
    os.makedirs(OUT, exist_ok=True)
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
