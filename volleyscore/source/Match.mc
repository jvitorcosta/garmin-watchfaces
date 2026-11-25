// Volleyball match state. The match is an event log (0 = point Left, 1 = point Right, 2 = serve
// Left, 3 = serve Right, 4..7 = tie-break rule 0..3); everything else is replayed from it, so
// undo is just "drop the last event".
// Tie-break rule (cap): 0 = win by 2, no limit. 1 = sudden death: at target-1 all the next point
// wins. 2 / 3 = a hard cap: the first to reach target+1 / target+2 wins (so the tie-break lasts at
// most 2 / 3 more points past the target).
import Toybox.Lang;

class Match {
    static const SETS_TO_WIN = 3;
    static const MAX_EVENTS = 400;

    var events as Array<Number> = [] as Array<Number>;
    var pts as Array<Number> = [0, 0] as Array<Number>;   // current set points [Left, Right]
    var sets as Array<Number> = [0, 0] as Array<Number>;  // sets won [Left, Right]
    var history as Array<Array<Number> > = [] as Array<Array<Number> >; // finished sets
    var serve as Number = 0;
    var over as Boolean = false;
    var cap as Number = 0;       // tie-break rule in force (0 = win by 2 only)
    var capChosen as Boolean = false; // a rule was picked this match, so don't ask again

    function initialize() {
        replay();
    }

    // Points needed to win the set being played: 25, or 15 in the deciding set.
    static function target(setsA as Number, setsB as Number) as Number {
        return (setsA + setsB == 2 * SETS_TO_WIN - 2) ? 15 : 25;
    }

    // A set is won at the target with a two-point lead; with a cap n > 0 it is also won by whoever
    // reaches target + n - 1 first.
    static function setWon(a as Number, b as Number, goal as Number, cap as Number) as Boolean {
        if ((a >= goal || b >= goal) && (a - b >= 2 || b - a >= 2)) {
            return true;
        }
        return cap > 0 && (a >= goal + cap - 1 || b >= goal + cap - 1);
    }

    static function capLabel(n as Number) as String {
        if (n == 1) {
            return "Sudden death";
        } else if (n == 2) {
            return "Max +1";
        } else if (n == 3) {
            return "Max +2";
        }
        return "Win by 2";
    }

    // True right after a set reaches target-1 all while no tie-break rule has been picked yet:
    // the moment to ask how the tie should be played out.
    function needsTieBreakAsk() as Boolean {
        return !over && !capChosen && pts[0] == pts[1] && pts[0] == currentTarget() - 1;
    }

    function currentTarget() as Number {
        return Match.target(sets[0], sets[1]);
    }

    function setNumber() as Number {
        return sets[0] + sets[1] + 1;
    }

    // Records a point for team 0 (Us) or 1 (Them). Returns 0 normal, 1 set won, 2 match won,
    // -1 ignored (match already over).
    function point(team as Number) as Number {
        if (over || events.size() >= MAX_EVENTS) {
            return -1;
        }
        events.add(team);
        return apply(team);
    }

    function setCap(n as Number) as Void {
        if (events.size() < MAX_EVENTS) {
            events.add(4 + n);
            cap = n;
            capChosen = true;
        }
    }

    function setServe(team as Number) as Void {
        if (events.size() < MAX_EVENTS) {
            events.add(2 + team);
            serve = team;
        }
    }

    // Drops the last event. Returns false when there is nothing to undo.
    function undo() as Boolean {
        if (events.size() == 0) {
            return false;
        }
        events = events.slice(0, events.size() - 1) as Array<Number>;
        replay();
        return true;
    }

    // New match; keeps the tie-break rule.
    function reset() as Void {
        var keep = cap;
        var chosen = capChosen;
        events = [] as Array<Number>;
        if (chosen) {
            events.add(4 + keep);
        }
        replay();
    }

    function replay() as Void {
        var log = events;
        pts = [0, 0] as Array<Number>;
        sets = [0, 0] as Array<Number>;
        history = [] as Array<Array<Number> >;
        serve = 0;
        over = false;
        cap = 0;
        capChosen = false;
        for (var i = 0; i < log.size(); i++) {
            var e = log[i];
            if (e >= 4) {
                cap = e - 4;
                capChosen = true;
            } else if (e >= 2) {
                serve = e - 2;
            } else if (!over) {
                apply(e);
            }
        }
    }

    private function apply(team as Number) as Number {
        pts[team] = pts[team] + 1;
        serve = team;
        if (!Match.setWon(pts[0], pts[1], currentTarget(), cap)) {
            return 0;
        }
        var winner = pts[0] > pts[1] ? 0 : 1;
        history.add([pts[0], pts[1]] as Array<Number>);
        sets[winner] = sets[winner] + 1;
        pts = [0, 0] as Array<Number>;
        if (sets[winner] >= SETS_TO_WIN) {
            over = true;
            return 2;
        }
        return 1;
    }

    // Storage form: only numbers in an array, so it survives the app exiting.
    function toStorage() as Array<Number> {
        return events;
    }

    function load(data) as Void {
        var ok = data instanceof Array && data.size() <= MAX_EVENTS;
        if (ok) {
            for (var i = 0; i < data.size(); i++) {
                var v = data[i];
                if (!(v instanceof Number) || v < 0 || v > 7) {
                    ok = false;
                    break;
                }
            }
        }
        events = ok ? data as Array<Number> : [] as Array<Number>;
        replay();
    }
}
