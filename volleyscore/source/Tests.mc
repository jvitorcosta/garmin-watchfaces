// Unit tests for Match. Build with --unit-test and run with monkeydo <prg> fr255 /t (Windows)
// while the simulator is open.
import Toybox.Lang;
import Toybox.Test;

function addPoints(m as Match, team as Number, n as Number) as Void {
    for (var i = 0; i < n; i++) {
        m.point(team);
    }
}

// Alternate points so neither side reaches the target early.
function tie(m as Match, n as Number) as Void {
    for (var i = 0; i < n; i++) {
        m.point(0);
        m.point(1);
    }
}

(:test)
function testSetTo25(logger as Test.Logger) as Boolean {
    var m = new Match();
    addPoints(m, 0, 24);
    Test.assertEqual(m.sets[0], 0);
    Test.assertEqual(m.point(0), 1);
    Test.assertEqual(m.sets[0], 1);
    Test.assertEqual(m.pts[0], 0);
    Test.assertEqual(m.history[0][0], 25);
    return true;
}

(:test)
function testWinByTwo(logger as Test.Logger) as Boolean {
    var m = new Match();
    tie(m, 24);                      // 24-24
    m.point(0);                      // 25-24: not over
    Test.assertEqual(m.sets[0], 0);
    m.point(1);                      // 25-25
    m.point(1);                      // 25-26
    Test.assertEqual(m.sets[1], 0);
    Test.assertEqual(m.point(1), 1); // 25-27 wins
    Test.assertEqual(m.sets[1], 1);
    return true;
}

(:test)
function testFifthSetTo15(logger as Test.Logger) as Boolean {
    var m = new Match();
    for (var i = 0; i < 2; i++) {
        addPoints(m, 0, 25);
        addPoints(m, 1, 25);
    }
    Test.assertEqual(m.setNumber(), 5);
    Test.assertEqual(m.currentTarget(), 15);
    addPoints(m, 0, 14);
    Test.assertEqual(m.point(0), 2);
    Test.assert(m.over);
    Test.assertEqual(m.sets[0], 3);
    return true;
}

(:test)
function testMatchOverIgnoresPoints(logger as Test.Logger) as Boolean {
    var m = new Match();
    addPoints(m, 0, 75);
    Test.assert(m.over);
    Test.assertEqual(m.point(1), -1);
    return true;
}

(:test)
function testUndo(logger as Test.Logger) as Boolean {
    var m = new Match();
    Test.assert(!m.undo());
    addPoints(m, 0, 25);             // set 1 to Us
    addPoints(m, 1, 3);
    Test.assert(m.undo());
    Test.assertEqual(m.pts[1], 2);
    m.undo();
    m.undo();
    m.undo();                        // back across the set boundary: 24-0
    Test.assertEqual(m.sets[0], 0);
    Test.assertEqual(m.pts[0], 24);
    Test.assertEqual(m.history.size(), 0);
    return true;
}

(:test)
function testServeFollowsRally(logger as Test.Logger) as Boolean {
    var m = new Match();
    Test.assertEqual(m.serve, 0);
    m.point(1);
    Test.assertEqual(m.serve, 1);
    m.setServe(0);
    Test.assertEqual(m.serve, 0);
    m.undo();
    Test.assertEqual(m.serve, 1);
    return true;
}

(:test)
function testStorageRoundTrip(logger as Test.Logger) as Boolean {
    var m = new Match();
    addPoints(m, 0, 25);
    addPoints(m, 1, 7);
    var n = new Match();
    n.load(m.toStorage());
    Test.assertEqual(n.sets[0], 1);
    Test.assertEqual(n.pts[1], 7);
    n.load([9, "x"]);                // bad data starts fresh
    Test.assertEqual(n.pts[0], 0);
    n.load(null);
    Test.assertEqual(n.events.size(), 0);
    return true;
}

(:test)
function testTieBreakCaps(logger as Test.Logger) as Boolean {
    Test.assert(!Match.setWon(25, 24, 25, 0));
    Test.assert(Match.setWon(26, 24, 25, 0));
    Test.assert(!Match.setWon(24, 24, 25, 1));
    Test.assert(Match.setWon(25, 24, 25, 1));      // sudden death
    Test.assert(!Match.setWon(25, 25, 25, 2));
    Test.assert(Match.setWon(26, 25, 25, 2));      // first to 26
    Test.assert(!Match.setWon(26, 26, 25, 3));
    Test.assert(Match.setWon(27, 26, 25, 3));      // first to 27
    return true;
}

(:test)
function testTieBreakIsLogged(logger as Test.Logger) as Boolean {
    var m = new Match();
    m.setCap(1);
    tie(m, 24);                                    // 24-24
    Test.assertEqual(m.point(0), 1);               // next point wins the set
    m.undo();
    Test.assertEqual(m.sets[0], 0);
    m.undo();
    m.undo();
    m.reset();
    Test.assertEqual(m.cap, 1);                    // a new match keeps the rule
    return true;
}

(:test)
function testTieBreakAskOnce(logger as Test.Logger) as Boolean {
    var m = new Match();
    addPoints(m, 0, 23);
    addPoints(m, 1, 22);
    Test.assert(!m.needsTieBreakAsk());   // 23-22
    m.point(1);                           // 23-23: not yet (needs 24-24)
    Test.assert(!m.needsTieBreakAsk());
    m.point(0);
    m.point(1);                           // 24-24
    Test.assert(m.needsTieBreakAsk());
    m.setCap(0);                          // chosen: never asked again
    Test.assert(!m.needsTieBreakAsk());
    m.reset();
    Test.assert(m.capChosen);             // a new match keeps the choice
    return true;
}

(:test)
function testTieBreakAskInDecidingSet(logger as Test.Logger) as Boolean {
    var m = new Match();
    for (var i = 0; i < 2; i++) {
        addPoints(m, 0, 25);
        addPoints(m, 1, 25);
    }
    addPoints(m, 0, 14);
    addPoints(m, 1, 13);
    m.point(1);                           // 14-14 in a set to 15
    Test.assert(m.needsTieBreakAsk());
    return true;
}

(:test)
function testSetGoal(logger as Test.Logger) as Boolean {
    var m = new Match();
    m.setGoal(0);                         // sets to 7
    Test.assertEqual(m.currentTarget(), 7);
    addPoints(m, 0, 7);
    Test.assertEqual(m.sets[0], 1);       // won at 7-0
    Test.assertEqual(m.currentTarget(), 7);
    for (var u = 0; u < 8; u++) {
        m.undo();                         // 7 points, then the goal change itself
    }
    Test.assertEqual(m.currentTarget(), 25);
    m.setGoal(4);                         // 21, deciding set 15
    for (var i = 0; i < 2; i++) {
        addPoints(m, 0, 21);
        addPoints(m, 1, 21);
    }
    Test.assertEqual(m.currentTarget(), 15);
    m.reset();
    Test.assertEqual(m.currentTarget(), 21);   // a new match keeps the goal
    m.setGoal(2);                         // sets to 12, deciding set 12 too
    Test.assertEqual(m.currentTarget(), 12);
    return true;
}
