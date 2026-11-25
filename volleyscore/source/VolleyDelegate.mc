import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.WatchUi;

// result: 0 point, 1 set won, 2 match won
function buzz(result as Number) as Void {
    if (!(Attention has :vibrate)) {
        return;
    }
    var p;
    if (result == 2) {
        p = [new Attention.VibeProfile(100, 400), new Attention.VibeProfile(0, 150),
             new Attention.VibeProfile(100, 400)];
    } else if (result == 1) {
        p = [new Attention.VibeProfile(100, 300), new Attention.VibeProfile(0, 100),
             new Attention.VibeProfile(100, 300)];
    } else {
        p = [new Attention.VibeProfile(70, 80)];
    }
    Attention.vibrate(p);
}

class VolleyDelegate extends WatchUi.BehaviorDelegate {
    var match as Match;
    var view as VolleyView;

    function initialize(m as Match, v as VolleyView) {
        BehaviorDelegate.initialize();
        match = m;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_UP) {
            return score(0);
        } else if (key == WatchUi.KEY_ENTER) {
            return score(1);
        } else if (key == WatchUi.KEY_DOWN) {
            if (match.undo()) {
                buzz(0);
                changed();
            }
            return true;
        }
        return false;
    }

    function score(team as Number) as Boolean {
        var r = match.point(team);
        if (r >= 0) {
            buzz(r);
            changed();
            if (r == 2) {
                WatchUi.pushView(new WinnerView(match), new WinnerDelegate(match), WatchUi.SLIDE_UP);
            } else if (r == 0 && match.needsTieBreakAsk()) {
                askTieBreak(match, 1);
            }
        }
        return true;
    }

    function changed() as Void {
        (Application.getApp() as VolleyApp).save();
        WatchUi.requestUpdate();
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Match"});
        menu.addItem(new WatchUi.MenuItem("Serve: Blue", null, :serveUs, {}));
        menu.addItem(new WatchUi.MenuItem("Serve: Red", null, :serveThem, {}));
        menu.addItem(new WatchUi.MenuItem("Points to win", "" + Match.GOALS[match.goalIdx], :goal, {}));
        menu.addItem(new WatchUi.MenuItem("Tie-break", Match.capLabel(match.cap), :tieBreak, {}));
        menu.addItem(new WatchUi.MenuItem("New match", null, :newMatch, {}));
        WatchUi.pushView(menu, new VolleyMenuDelegate(match), WatchUi.SLIDE_UP);
        return true;
    }
}

class VolleyMenuDelegate extends WatchUi.Menu2InputDelegate {
    var match as Match;

    function initialize(m as Match) {
        Menu2InputDelegate.initialize();
        match = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :newMatch) {
            WatchUi.pushView(new WatchUi.Confirmation("New match?"), new NewMatchConfirm(match),
                             WatchUi.SLIDE_UP);
            return;
        }
        if (id == :goal) {
            pushGoalMenu(match);
            return;
        }
        if (id == :tieBreak) {
            pushTieBreakMenu(match, "Tie-break", false, 2);
            return;
        }
        match.setServe(id == :serveUs ? 0 : 1);
        (Application.getApp() as VolleyApp).save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Points needed to win a set: the choice is logged (so DOWN undoes it) and kept for new matches.
function pushGoalMenu(match as Match) as Void {
    var menu = new WatchUi.Menu2({:title => "Points to win"});
    for (var n = 0; n < Match.GOALS.size(); n++) {
        var note = n == match.goalIdx ? "current" : (Match.GOALS[n] == 15 ? "also last set" : null);
        menu.addItem(new WatchUi.MenuItem("" + Match.GOALS[n], note, n, {}));
    }
    WatchUi.pushView(menu, new GoalDelegate(match), WatchUi.SLIDE_UP);
}

class GoalDelegate extends WatchUi.Menu2InputDelegate {
    var match as Match;

    function initialize(m as Match) {
        Menu2InputDelegate.initialize();
        match = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var n = item.getId() as Number;
        if (n != match.goalIdx) {
            match.setGoal(n);
            (Application.getApp() as VolleyApp).save();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);   // this menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);   // the match menu
        WatchUi.requestUpdate();
    }
}

class NewMatchConfirm extends WatchUi.ConfirmationDelegate {
    var match as Match;

    function initialize(m as Match) {
        ConfirmationDelegate.initialize();
        match = m;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            match.reset();
            (Application.getApp() as VolleyApp).save();
            WatchUi.popView(WatchUi.SLIDE_DOWN); // the menu underneath the dialog
        }
        return true;
    }
}

// The scoreboard just reached target-1 all: ask once how the tie is played out. The first item
// (Win by 2, the usual rule) is already highlighted, so one press carries on; the last item takes
// the point back in case it was a mistake.
function askTieBreak(match as Match, pops as Number) as Void {
    var t = match.currentTarget() - 1;
    buzz(1);
    pushTieBreakMenu(match, "Tied " + t + "-" + t, true, pops);
}

function pushTieBreakMenu(match as Match, title as String, withUndo as Boolean, pops as Number) as Void {
    var t = match.currentTarget();
    var menu = new WatchUi.Menu2({:title => title});
    var sub = ["no limit", "next point wins", "first to " + (t + 1), "first to " + (t + 2)];
    for (var n = 0; n < 4; n++) {
        var note = sub[n];
        if (!withUndo && n == match.cap) {
            note = "current";
        }
        menu.addItem(new WatchUi.MenuItem(Match.capLabel(n), note, n, {}));
    }
    if (withUndo) {
        menu.addItem(new WatchUi.MenuItem("Undo that point", null, :undo, {}));
    }
    WatchUi.pushView(menu, new TieBreakDelegate(match, pops), WatchUi.SLIDE_UP);
}

class TieBreakDelegate extends WatchUi.Menu2InputDelegate {
    var match as Match;
    var pops as Number;

    function initialize(m as Match, p as Number) {
        Menu2InputDelegate.initialize();
        match = m;
        pops = p;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :undo) {
            match.undo();
        } else {
            match.setCap(id as Number);
        }
        (Application.getApp() as VolleyApp).save();
        for (var i = 0; i < pops; i++) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        WatchUi.requestUpdate();
    }
}
