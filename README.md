# Garmin watch faces

João's Connect IQ watch faces for the Forerunner 255.

| Face | What it shows |
|---|---|
| [`pokeface/`](pokeface) | **Pokéface**: a Pokémon Emerald battle scene with the time, steps and the week's runs |

## Build

Needs the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and your own developer key.

```bash
python tools/gen_pokeface.py
```

That fetches the sprites and font once (into `pokefont-src/`, git-ignored) and writes `pokeface/resources/gen/`. Then build it:

```bash
monkeyc -d fr255 -f pokeface/monkey.jungle -o pokeface/bin/Pokeface.prg -y <your developer_key.der>
```

To install it, copy the `.prg` into the watch's `GARMIN/APPS` folder over USB, then unplug the watch.

## History

Pokéface began in [jvitorcosta/spotify-car-deck](https://github.com/jvitorcosta/spotify-car-deck) and moved here with its git history on 2026-10-28. Its design notes are in [`docs/`](docs).

## Credits

The Pokémon sprites and the Emerald font are Nintendo / Game Freak / Creatures art, from the [pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion) decompilation (the later species drawn by its artists). They're downloaded at build time and never committed. Pokémon is a trademark of Nintendo, Game Freak and Creatures; this is an unofficial fan project for personal use.
