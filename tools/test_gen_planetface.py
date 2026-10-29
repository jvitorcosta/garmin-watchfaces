"""Host tests for tools/gen_planetface.py (no network; needs Pillow).
Run: python tools/test_gen_planetface.py"""
import os
import sys
import unittest

try:
    from PIL import Image
except ImportError:
    Image = None
if Image is None:
    raise unittest.SkipTest("gen_planetface needs Pillow (pip install -r tools/requirements.txt)")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_planetface as g  # noqa: E402


class Disc(unittest.TestCase):
    def test_top_of_disc_is_the_pole(self):
        inside, mu, lat = g.on_disc(g.CX, g.CY - g.R + 1)
        self.assertTrue(inside)
        self.assertGreater(lat, 80)   # a pixel below the pole is already ~84°

    def test_corner_is_off_the_disc(self):
        self.assertFalse(g.on_disc(0, 0)[0])


class Dither(unittest.TestCase):
    def test_only_watch_levels(self):
        im = Image.new("RGB", (8, 8), (120, 30, 200))
        cols = {c for _, c in g.dither(im).getcolors()}
        self.assertTrue(all(v in g.LEVELS for c in cols for v in c))

    def test_limit_keeps_black_and_caps_colours(self):
        im = Image.new("RGB", (20, 1))
        for x in range(20):
            im.putpixel((x, 0), (g.LEVELS[x % 4], g.LEVELS[(x // 4) % 4], 0xFF))
        out, pal = g.limit(im, 4)
        self.assertEqual(len(pal), 4)
        self.assertIn((0, 0, 0), pal)
        self.assertTrue({c for _, c in out.getcolors()} <= set(pal))


class Planets(unittest.TestCase):
    def test_each_planet_fits_the_watch(self):
        for body in ("moon", "saturn"):   # the cratered and the ringed one; all seven take ~7 s
            im, pal = g.planet(body)
            self.assertEqual(im.size, (g.W, g.H))
            self.assertLessEqual(len(pal), g.MAX_COLOURS)
            self.assertEqual(im.getpixel((0, 0)), (0, 0, 0))   # off the disc: black


class Fonts(unittest.TestCase):
    def test_bmfont_lists_every_char(self):
        text, page = g.bmfont("t", 20, "0:A")
        self.assertIn("chars count=3", text)
        self.assertEqual(page.height, sum(g.ImageFont.truetype(g.FONT, 20).getmetrics()))

    def test_gen_xml_names(self):
        xml = g.gen_xml([[(0, 0, 0)]] * 7)
        self.assertIn('id="Planet6"', xml)
        self.assertIn('id="VtTime"', xml)
        self.assertIn('id="LauncherIcon"', xml)


if __name__ == "__main__":
    unittest.main()
