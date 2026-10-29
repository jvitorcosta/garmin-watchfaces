"""Build the Planet face's pictures and fonts (planetface/resources/gen/).
Run: python tools/gen_planetface.py

Planets: the day's body seen from close by, its top filling the bottom of the round screen. Each
is drawn here (no photos yet: these stand in for NASA's until the owner picks them) as a
260 x 143 picture of the screen's rows 117-259: a disc of radius R centred on screen row 330, a
few bands, spots or craters, darker toward the edge. Then ordered (Bayer) dithering snaps it to
the Forerunner 255's 64 colours, and the 16 most used become its palette (4 bits a pixel on the
watch instead of 8). planet0..6 follow Garmin's day_of_week - 1: Sun, Moon, Mars, Mercury,
Jupiter, Venus, Saturn (Sunday to Saturday, the bodies the weekdays are named after).
Fonts: VT323 (tools/fonts, OFL) as 1-bit BMFont fonts: vt_time (digits and ':') for the time,
vt_small for the telemetry, vt_tiny for the date line. gen.xml lists all of them as resources.
Spec: docs/specs/2026-10-26-planetface-design.md
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "planetface", "resources", "gen")
FONT = os.path.join(ROOT, "tools", "fonts", "VT323-Regular.ttf")
LEVELS = (0x00, 0x55, 0xAA, 0xFF)
W, H = 260, 143          # the picture: screen rows TOP..259
# the telemetry box covers picture x 66-194, y 21-99: features worth seeing go beside or below it
TOP = 117
CX, CY, R = 130, 330 - TOP, 210   # the disc, in picture coordinates
MAX_COLOURS = 16
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
BODIES = ["sun", "moon", "mars", "mercury", "jupiter", "venus", "saturn"]
GLYPHS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz :./-%>,"
FONTS = [("vt_time", 64, "0123456789:"), ("vt_small", 20, GLYPHS), ("vt_tiny", 16, GLYPHS)]


def noise(w, h, cell, seed):
    """Smooth value noise in 0..1: a coarse random grid blown up bicubically."""
    rnd = random.Random(seed)
    gw, gh = max(2, w // cell + 2), max(2, h // cell + 2)
    g = Image.new("L", (gw, gh))
    g.putdata([rnd.randrange(256) for _ in range(gw * gh)])
    big = g.resize((gw * cell, gh * cell), Image.BICUBIC)
    return [[big.getpixel((x, y)) / 255.0 for x in range(w)] for y in range(h)]


def mix(a, b, t):
    t = min(1.0, max(0.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def scale(c, k):
    return tuple(v * k for v in c)


def on_disc(x, y):
    """(inside, mu, latitude in degrees): mu is 1 at the disc's centre and 0 at its edge."""
    dx, dy = x - CX, y - CY
    rr = (dx * dx + dy * dy) / float(R * R)
    if rr >= 1.0:
        return False, 0.0, 0.0
    return True, math.sqrt(1.0 - rr), math.degrees(math.asin(max(-1.0, min(1.0, -dy / float(R)))))


def craters(rnd, n, rmin, rmax):
    return [(rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(rmin, rmax)) for _ in range(n)]


def crater_shade(x, y, cs):
    """Darker floor, a light rim on the lower right: 1.0 where there is no crater."""
    k = 1.0
    for cx, cy, r in cs:
        d = math.hypot(x - cx, y - cy)
        if d < r * 0.8:
            k *= 0.8
        elif d < r and (x - cx) + (y - cy) > 0:
            k *= 1.18
    return k


def surface(body):
    """The body's colour at each picture pixel, before shading toward the edge; None off the disc."""
    rnd = random.Random(body)
    fine = noise(W, H, 6, body + "f")
    coarse = noise(W, H, 40, body + "c")
    if body in ("moon", "mercury"):
        cs = craters(rnd, 40 if body == "moon" else 90, 3, 16 if body == "moon" else 10)
    else:
        cs = []

    def colour(x, y, lat):
        f, c = fine[y][x], coarse[y][x]
        if body == "sun":
            base = mix((255, 200, 40), (255, 140, 0), f)
            for sx, sy, sr in ((40, 52, 8), (222, 64, 6), (140, 118, 6)):   # clear of the telemetry box
                d = math.hypot(x - sx, y - sy)
                if d < sr:
                    base = (60, 20, 0) if d < sr * 0.55 else (170, 70, 0)
            return base
        if body == "moon":
            base = mix((200, 200, 195), (150, 150, 145), f * 0.6)
            if c > 0.62:
                base = mix(base, (95, 95, 92), (c - 0.62) * 4)
            return scale(base, crater_shade(x, y, cs))
        if body == "mercury":
            return scale(mix((165, 145, 125), (120, 105, 90), f * 0.5 + c * 0.4), crater_shade(x, y, cs))
        if body == "mars":
            if lat > 72 + f * 6:
                return (240, 235, 225)
            base = mix((215, 95, 35), (170, 60, 20), f * 0.6)
            if c > 0.58:
                base = mix(base, (90, 35, 15), (c - 0.58) * 3.5)
            return base
        if body == "jupiter":
            v = lat + (f - 0.5) * 5 + math.sin(x / 17.0 + lat) * 1.2
            bands = [(84, (225, 210, 180)), (74, (190, 150, 105)), (66, (235, 220, 190)), (57, (160, 110, 70)),
                     (49, (230, 205, 160)), (40, (175, 120, 75)), (32, (240, 225, 195)), (0, (200, 160, 110))]
            base = next(col for edge, col in bands if v >= edge)
            if math.hypot((x - 224) / 1.9, y - 72) < 9:   # the Great Red Spot, right of the box
                base = (200, 80, 50)
            return base
        if body == "venus":
            v = lat + (c - 0.5) * 18 + math.sin(x / 26.0) * 4
            return mix((250, 235, 180), (195, 150, 85), 0.5 + 0.5 * math.sin(v / 5.0) * (0.6 + f * 0.4))
        if body == "saturn":
            v = lat + (f - 0.5) * 2
            bands = [(80, (200, 185, 140)), (64, (230, 205, 150)), (55, (205, 170, 110)), (44, (240, 215, 160)),
                     (36, (215, 180, 120)), (0, (235, 210, 155))]
            return next(col for edge, col in bands if v >= edge)
        raise ValueError("unknown body %r" % body)

    return colour


def ring(x, y):
    """Saturn's rings, tilted across the lower picture: (colour, in front) or None."""
    rcx, rcy = CX, 100
    dx, dy = x - rcx, (y - rcy) / 0.22
    r = math.hypot(dx, dy)
    if r < 98 or r > 175 or 140 < r < 146:   # the gap at 140-146 is the Cassini division
        return None
    # inside 105: the rings' shadow on the planet, so the bright ring stands out from the bands
    col = (60, 50, 35) if r < 105 else ((250, 240, 205) if r < 140 else (150, 130, 95))
    return col, y >= rcy


def render(body):
    """The full-colour picture of `body` on black."""
    im = Image.new("RGB", (W, H))
    colour = surface(body)
    px = im.load()
    for y in range(H):
        for x in range(W):
            inside, mu, lat = on_disc(x, y)
            c = (0, 0, 0)
            if inside:
                k = (0.35 + 0.65 * mu ** 0.5) if body == "sun" else (0.45 + 0.55 * mu ** 0.6)
                c = scale(colour(x, y, lat), k)
            if body == "saturn":
                rg = ring(x, y)
                if rg is not None and (rg[1] or not inside):
                    c = rg[0]
            px[x, y] = tuple(int(max(0, min(255, v))) for v in c)
    return im


def dither(im):
    """Ordered dithering to the watch's 4 levels a channel."""
    out = Image.new("RGB", im.size)
    src, dst = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            t = (BAYER[y % 4][x % 4] + 0.5) / 16.0 - 0.5
            dst[x, y] = tuple(min(LEVELS, key=lambda lv: abs(lv - (v + t * 85))) for v in src[x, y])
    return out


def limit(im, n=MAX_COLOURS):
    """Keep the n most used colours (black always); the rest go to the nearest kept one."""
    counts = sorted(im.getcolors(W * H), reverse=True)
    keep = [c for _, c in counts[:n]]
    if (0, 0, 0) not in keep:
        keep = keep[:n - 1] + [(0, 0, 0)]
    near = {}
    out = Image.new("RGB", im.size)
    src, dst = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            c = src[x, y]
            if c not in near:
                near[c] = min(keep, key=lambda k: sum((a - b) ** 2 for a, b in zip(c, k)))
            dst[x, y] = near[c]
    return out, sorted(keep)


def planet(body):
    """The watch-ready picture of `body` and its palette."""
    return limit(dither(render(body)))


def bmfont(name, size, chars):
    """A 1-bit BMFont (text and page) of VT323 at `size` px: each glyph in a cell as tall as the line."""
    f = ImageFont.truetype(FONT, size)
    ascent, descent = f.getmetrics()
    h = ascent + descent
    cells = []
    for ch in chars:
        adv = int(round(f.getlength(ch)))
        g = Image.new("L", (max(adv, 1), h), 0)
        ImageDraw.Draw(g).text((0, 0), ch, font=f, fill=255)
        cells.append((ch, g.point(lambda v: 255 if v >= 128 else 0), adv))
    page = Image.new("RGBA", (sum(g.width + 1 for _, g, _ in cells), h), (0, 0, 0, 0))
    rows, x = [], 0
    for ch, g, adv in cells:
        page.paste(Image.new("RGBA", g.size, (255, 255, 255, 255)), (x, 0), g)
        rows.append("char id=%d x=%d y=0 width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                    % (ord(ch), x, g.width, h, adv))
        x += g.width + 1
    text = ("info face=\"%s\" size=%d bold=0 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=0 aa=1 "
            "padding=0,0,0,0 spacing=1,1\n" % (name, size)
            + "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0\n" % (h, ascent, page.width, h)
            + "page id=0 file=\"%s.png\"\n" % name + "chars count=%d\n" % len(rows) + "\n".join(rows) + "\n")
    return text, page


def icon():
    """The 40 x 40 launcher icon: a small ringed planet."""
    im = Image.new("RGBA", (40, 40), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 16, 37, 25), outline=(0xAA, 0xAA, 0x55, 255), width=2)
    d.ellipse((11, 9, 28, 30), fill=(0xFF, 0xAA, 0x55, 255))
    d.arc((2, 16, 37, 25), 0, 180, fill=(0xFF, 0xFF, 0xAA, 255), width=2)
    return im


def gen_xml(palettes):
    bitmaps = "\n".join('    <bitmap id="Planet%d" filename="planet%d.png" dithering="none"><palette>%s</palette></bitmap>'
                        % (i, i, "".join("<color>%02X%02X%02X</color>" % c for c in pal))
                        for i, pal in enumerate(palettes))
    bitmaps += '\n    <bitmap id="LauncherIcon" filename="launcher_icon.png"/>'
    fonts = "\n".join('    <font id="%s" filename="%s.fnt" antialias="false"/>'
                      % ("".join(p.title() for p in name.split("_")), name) for name, _, _ in FONTS)
    return "<resources>\n<drawables>\n" + bitmaps + "\n</drawables>\n<fonts>\n" + fonts + "\n</fonts>\n</resources>\n"


def main():
    os.makedirs(OUT, exist_ok=True)
    palettes = []
    for i, body in enumerate(BODIES):
        im, pal = planet(body)
        im.save(os.path.join(OUT, "planet%d.png" % i))
        palettes.append(pal)
        print("%-8s %d colours" % (body, len(pal)))
    for name, size, chars in FONTS:
        text, page = bmfont(name, size, chars)
        page.save(os.path.join(OUT, name + ".png"))
        with open(os.path.join(OUT, name + ".fnt"), "w", encoding="utf-8") as f:
            f.write(text)
    icon().save(os.path.join(OUT, "launcher_icon.png"))
    with open(os.path.join(OUT, "gen.xml"), "w", encoding="utf-8") as f:
        f.write(gen_xml(palettes))


if __name__ == "__main__":
    main()
