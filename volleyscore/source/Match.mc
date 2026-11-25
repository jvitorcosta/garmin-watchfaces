// Volleyball match state. The match is an event log (0 = point Us, 1 = point Them, 2 = serve Us,
// 3 = serve Them); everything else is replayed from it, so undo is just "drop the last event".
import Toybox.Lang;

class Match {
    static const SETS_TO_WIN = 3;
    static const MAX_EVENTS = 400;

    var events as Array<Number> = [] as Array<Number>;
    var pts as Array<Number> = [0, 0] as Array<Number>;   // current set points [Us, Them]
    var sets as Array<Number> = [0, 0] as Array<Number>;  // sets won [Us, Them]
    var history as Array<Array<Number> > = [] as Array<Array<Number> >; // finished sets
    var serve as Number = 0;
    var over as Boolean = false;

    function initialize() {
        replay();
    }

    // Points needed to win the set being played: 25, or 15 in the deciding set.
    static function target(setsA as Number, setsB as Number) as Number {
        return (setsA + setsB == 2 * SETS_TO_WIN - 2) ? 15 : 25;
    }

    // A set is won at the target with a two-point lead.
    static function setWon(a as Number, b as Number, goal as Number) as Boolean {
        return (a >= goal || b >= goal) && (a - b >= 2 || b - a >= 2);
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

    function reset() as Void {
        events = [] as Array<Number>;
        replay();
    }

    function replay() as Void {
        var log = events;
        pts = [0, 0] as Array<Number>;
        sets = [0, 0] as Array<Number>;
        history = [] as Array<Array<Number> >;
        serve = 0;
        over = false;
        for (var i = 0; i < log.size(); i++) {
            var e = log[i];
            if (e >= 2) {
                serve = e - 2;
            } else if (!over) {
                apply(e);
            }
        }
    }

    private function apply(team as Number) as Number {
        pts[team] = pts[team] + 1;
        serve = team;
        if (!Match.setWon(pts[0], pts[1], currentTarget())) {
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
                if (!(v instanceof Number) || v < 0 || v > 3) {
                    ok = false;
                    break;
                }
            }
        }
        events = ok ? data as Array<Number> : [] as Array<Number>;
        replay();
    }
}
