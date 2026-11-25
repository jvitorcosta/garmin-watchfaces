# Volley Score

A volleyball scoreboard for the Forerunner 255. Sideloaded only, not published to the Connect IQ Store.

![Volley Score in the Forerunner 255 simulator](../docs/images/volleyscore-sim.png)

- Split screen: each team's half fills with its colour (light blue left, red right) as it scores, in proportion to the points needed to win the set, with a thin strip showing who is who at 0-0. Big white points, and three dots above each score are the sets won (filled = won). A white ribbon on top shows the set and the score that wins it.
- Sets go to 25, the fifth to 15; first to 3 sets wins the match.
- Tie-break (menu): **Win by 2** (default), **Sudden death** (tied one point short of the target, the next point wins), **Max +1** (first to target + 1) or **Max +2** (first to target + 2). It applies from that point on and a new match keeps the choice.
- The serve marker (small white ball under the score) follows the team that scored the last point; change it from the menu.
- A short buzz per point, a double buzz when a set ends, a long double buzz when the match ends.
- The score is saved after every change, so leaving the app (or the watch sleeping) never loses the match.

## Buttons

Laid out like the screen: left buttons for the left team, right button for the right team.

| Button | Does |
|---|---|
| UP | point for the **left** (blue) team |
| START | point for the **right** (red) team |
| DOWN | undo the last action (as many times as you like, even back into a finished set) |
| hold UP | menu: serve blue / serve red / tie-break / new match |
| BACK | leave the app; reopen it and the score is still there |

## Build

Needs the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and your own developer key (`.der`).

```bash
monkeyc -d fr255 -f volleyscore/monkey.jungle -o volleyscore/bin/VolleyScore.prg -y <your developer_key.der>
```

## Tests

The match rules (set to 25, win by 2, tie-break caps, fifth set to 15, undo across sets, serve, saving) have unit tests in `source/Tests.mc`. Open the simulator (`connectiq`), then:

```bash
monkeyc -d fr255 -f volleyscore/monkey.jungle -o volleyscore/bin/VolleyTest.prg -y <your developer_key.der> --unit-test
monkeydo volleyscore/bin/VolleyTest.prg fr255 /t
```

## Sideload

1. Connect the watch over USB.
2. Copy `volleyscore/bin/VolleyScore.prg` into the watch's `GARMIN/APPS` folder.
3. Unplug the watch. Volley Score shows up in the app list (START, then scroll to it).

## How it works

`Match.mc` keeps the match as a list of events (point left, point right, serve change, tie-break rule) and replays it to get the score, so undo is just dropping the last event and the saved state is that list. `VolleyView.mc` draws it (the Bebas Neue fonts are built by `python tools/gen_volleyscore.py` and committed in `resources/gen/`), `VolleyDelegate.mc` handles the buttons, menu and haptics.
