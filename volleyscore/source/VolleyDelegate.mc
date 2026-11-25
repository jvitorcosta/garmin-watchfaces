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
        if (id == :tieBreak) {
            var menu = new WatchUi.Menu2({:title => "Tie-break"});
            for (var n = 0; n < 4; n++) {
                menu.addItem(new WatchUi.MenuItem(Match.capLabel(n), n == match.cap ? "current" : null, n, {}));
            }
            WatchUi.pushView(menu, new TieBreakDelegate(match), WatchUi.SLIDE_UP);
            return;
        }
        match.setServe(id == :serveUs ? 0 : 1);
        (Application.getApp() as VolleyApp).save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
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

class TieBreakDelegate extends WatchUi.Menu2InputDelegate {
    var match as Match;

    function initialize(m as Match) {
        Menu2InputDelegate.initialize();
        match = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        match.setCap(item.getId() as Number);
        (Application.getApp() as VolleyApp).save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN); // and the match menu
        WatchUi.requestUpdate();
    }
}
