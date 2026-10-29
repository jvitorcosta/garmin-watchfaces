# Planet face (Forerunner 255) — design

A watch face showing the body today's weekday is named after, under a mission-control readout.
It's a prototype for a face that might be sold later, so everything in it is original or
public domain: no NASA logos or names, no third-party art.

## Layout (mockup "A + B, week", agreed 2026-10-26)

Top to bottom on black, all text in VT323 (OFL):

- **Date line**: weekday, day, month (`MON 26 OCT`), grey.
- **Time**: large and white; 12 or 24 h following the watch setting.
- **MET**: whole days since Apollo 11 landed (1969-07-20), local date, gold (`MET 20917d`).
- **Planet**: today's body fills screen rows 117-259 (a disc of radius 210 centred on row 330).
- **Step arc**: the step goal as a gold arc just outside the disc's edge (radius 213, 125° to 55°)
  over a dark track.
- **Telemetry box** (x 66-194, y 138-216, solid black, dark teal border): `> NAME` in gold,
  then teal labels with white values: LIGHT (light delay now), DIST (distance now), FUEL (battery
  %), STEPS.

## Bodies

Garmin's `day_of_week - 1`: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn (Sunday to
Saturday). Distances come from JPL's (Standish) mean orbital elements, valid 1800-2050, solved
with Kepler's equation each minute. The Moon uses the largest terms of Meeus's distance series.
Checked against Venus's closest approach 2026-10-24, Saturn's opposition 2026-10-04, Mars's
opposition 2025-01-12, and the Moon's perigee and apogee in November 2025.

## Pictures

`tools/gen_planetface.py` draws each body (bands, spots, craters, polar cap, Saturn's rings),
darkens it toward the edge, ordered-dithers it to the FR255's 64 colours, and keeps ≤16 colours
as the bitmap palette (4 bits a pixel, ~19 KB). Features worth seeing sit beside or below the
telemetry box. These drawings stand in for real NASA photos (public domain, credited to NASA
only) until the owner picks them.

## Later

- Real NASA photos per body.
- Separate builds for AMOLED watches (always-on screen: outlined digits, thin planet edge).
- A one-line fact per body; Uranus, Neptune and Pluto as extras; a store name and a paid unlock.
- It lives in the public garmin-watchfaces repo; decide before selling whether the source should go private.
