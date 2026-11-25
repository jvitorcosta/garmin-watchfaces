# Volley Score

A volleyball scoreboard for the Forerunner 255. Sideloaded only, not published to the Connect IQ Store.

- Sets go to 25, the fifth to 15, always win by 2; first to 3 sets wins the match.
- The serve marker (yellow dot) follows the team that scored the last point; change it from the menu.
- A short buzz per point, a double buzz when a set ends, a long double buzz when the match ends.
- The score is saved after every change, so leaving the app (or the watch sleeping) never loses the match.

## Buttons

| Button | Does |
|---|---|
| UP | point for **Us** (top half) |
| DOWN | point for **Them** (bottom half) |
| START | undo the last action (as many times as you like, even back into a finished set) |
| hold UP | menu: serve Us / serve Them / new match |
| BACK | leave the app; reopen it and the score is still there |

## Build

Needs the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and your own developer key (`.der`).

```bash
monkeyc -d fr255 -f volleyscore/monkey.jungle -o volleyscore/bin/VolleyScore.prg -y <your developer_key.der>
```

## Tests

The match rules (set to 25, win by 2, fifth set to 15, undo across sets, serve, saving) have unit tests in `source/Tests.mc`. Open the simulator (`connectiq`), then:

```bash
monkeyc -d fr255 -f volleyscore/monkey.jungle -o volleyscore/bin/VolleyTest.prg -y <your developer_key.der> --unit-test
monkeydo volleyscore/bin/VolleyTest.prg fr255 /t
```

## Sideload

1. Connect the watch over USB.
2. Copy `volleyscore/bin/VolleyScore.prg` into the watch's `GARMIN/APPS` folder.
3. Unplug the watch. Volley Score shows up in the app list (START, then scroll to it).

## How it works

`Match.mc` keeps the match as a list of events (point Us, point Them, serve change) and replays it to get the score, so undo is just dropping the last event and the saved state is that list. `VolleyView.mc` draws it, `VolleyDelegate.mc` handles the buttons, menu and haptics.
