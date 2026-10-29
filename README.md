# Garmin watch faces

João's Connect IQ watch faces for the Forerunner 255.

| Face | What it shows |
|---|---|
| [`pokeface/`](pokeface) | **Pokéface**: a Pokémon Emerald battle scene with the time, steps and the week's runs |
| [`planetface/`](planetface) | **Planet of the Day**: the body each weekday is named after (Sunday the Sun … Saturday Saturn) under a mission-control readout: days since Apollo 11, live light delay and distance, battery, steps |

## Build

Needs the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and your own developer key.

```bash
python tools/gen_pokeface.py
```

That fetches the sprites and font once (into `pokefont-src/`, git-ignored) and writes `pokeface/resources/gen/`. Then build it:

```bash
monkeyc -d fr255 -f pokeface/monkey.jungle -o pokeface/bin/Pokeface.prg -y <your developer_key.der>
```

Planet of the Day's pictures and fonts are committed, so it builds straight away; `python tools/gen_planetface.py` redraws them (it needs only Pillow).

```bash
monkeyc -d fr255 -f planetface/monkey.jungle -o planetface/bin/Planet.prg -y <your developer_key.der>
```

To install a face, copy the `.prg` into the watch's `GARMIN/APPS` folder over USB, then unplug the watch.

## History

Pokéface began in [jvitorcosta/car-cyberdeck](https://github.com/jvitorcosta/car-cyberdeck) and moved here with its git history on 2026-10-28. Planet of the Day was prototyped there too and moved here before its first commit. Design notes for both are in [`docs/`](docs).

## Credits

The Pokémon sprites and the Emerald font are Nintendo / Game Freak / Creatures art, from the [pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion) decompilation (the later species drawn by its artists). They're downloaded at build time and never committed. Pokémon is a trademark of Nintendo, Game Freak and Creatures; this is an unofficial fan project for personal use.

Planet of the Day's planets are original drawings made by `tools/gen_planetface.py`. Its font is [VT323](https://fonts.google.com/specimen/VT323) (© The VT323 Project Authors), under the SIL Open Font License ([`tools/fonts/VT323-OFL.txt`](tools/fonts/VT323-OFL.txt)).
