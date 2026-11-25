// The hold-UP menu: big rows (serve choices in the team colours, settings with their current
// value), and wheel pickers (roulette selectors) for the points to win and the tie-break rule.
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MenuRow extends WatchUi.CustomMenuItem {
    var label as String;
    var value as String?;
    var fill as Number?;      // team colour, or null for a plain row
    var marked as Boolean;    // draws a ball: this team is serving
    var font as WatchUi.FontResource;

    function initialize(id as Symbol, text as String, val as String?, color as Number?, mark as Boolean) {
        CustomMenuItem.initialize(id, {});
        label = text.toUpper();
        value = val == null ? null : val.toUpper();
        fill = color;
        marked = mark;
        font = WatchUi.loadResource(Rez.Fonts.BebasLabel) as WatchUi.FontResource;
    }

    function draw(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var pad = 5;
        var col = fill != null ? fill as Number : 0x20262E;
        dc.setColor(col, col);
        dc.fillRoundedRectangle(pad, pad, w - 2 * pad, h - 2 * pad, (h - 2 * pad) / 2);
        if (isFocused()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawRoundedRectangle(pad, pad, w - 2 * pad, h - 2 * pad, (h - 2 * pad) / 2);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var vcenter = Graphics.TEXT_JUSTIFY_VCENTER;
        if (value == null && !marked) {
            dc.drawText(w / 2, h / 2, font, label, Graphics.TEXT_JUSTIFY_CENTER | vcenter);
            return;
        }
        dc.drawText(w * 14 / 100, h / 2, font, label, Graphics.TEXT_JUSTIFY_LEFT | vcenter);
        if (marked) {
            dc.fillCircle(w * 84 / 100, h / 2, 8);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(w * 84 / 100, h / 2, 8);
        } else {
            dc.drawText(w * 86 / 100, h / 2, font, value as String, Graphics.TEXT_JUSTIFY_RIGHT | vcenter);
        }
    }
}

function pushMatchMenu(match as Match) as Void {
    var title = new WatchUi.Text({:text => "MATCH", :color => Graphics.COLOR_LT_GRAY, :font => Graphics.FONT_XTINY,
                                  :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER});
    var menu = new WatchUi.CustomMenu(58, Graphics.COLOR_BLACK, {:title => title, :titleItemHeight => 40});
    menu.addItem(new MenuRow(:serveUs, "Serve blue", null, VolleyView.BLUE, match.serve == 0));
    menu.addItem(new MenuRow(:serveThem, "Serve red", null, VolleyView.RED, match.serve == 1));
    menu.addItem(new MenuRow(:goal, "Points to win", "" + match.goal, null, false));
    menu.addItem(new MenuRow(:tieBreak, "Tie-break", Match.capLabel(match.cap), null, false));
    menu.addItem(new MenuRow(:newMatch, "New match", null, null, false));
    WatchUi.pushView(menu, new VolleyMenuDelegate(match), WatchUi.SLIDE_UP);
}

// A roulette-style selector: the current value big in the middle, the ones before and after it
// dimmed above and below. UP / DOWN turn the wheel (wrapping round), START confirms, BACK cancels.
class WheelView extends WatchUi.View {
    var kind as Symbol;
    var title as String;
    var labels as Array<String>;
    var index as Number;
    var bigFont as WatchUi.FontResource?;
    var labelFont as WatchUi.FontResource?;

    function initialize(k as Symbol, t as String, l as Array<String>, start as Number) {
        View.initialize();
        kind = k;
        title = t;
        labels = l;
        index = start;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        bigFont = WatchUi.loadResource(Rez.Fonts.BebasScore) as WatchUi.FontResource;
        labelFont = WatchUi.loadResource(Rez.Fonts.BebasLabel) as WatchUi.FontResource;
    }

    function turn(by as Number) as Void {
        var n = labels.size();
        index = (index + by + n) % n;
        WatchUi.requestUpdate();
    }

    function at(offset as Number) as String {
        var n = labels.size();
        return labels[(index + offset + n * 2) % n];
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mid = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 9 / 100, labelFont, title, mid);

        // Values before and after, fading away from the middle.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 27 / 100, labelFont, at(-1).toUpper(), mid);
        dc.drawText(w / 2, h * 73 / 100, labelFont, at(1).toUpper(), mid);
        // Chevrons say the wheel turns with UP and DOWN.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[w / 2 - 9, h * 20 / 100], [w / 2 + 9, h * 20 / 100], [w / 2, h * 16 / 100]]);
        dc.fillPolygon([[w / 2 - 9, h * 80 / 100], [w / 2 + 9, h * 80 / 100], [w / 2, h * 84 / 100]]);

        if (kind == :goal) {
            // Big digits with a dark outline, like on the scoreboard.
            var o = [[-3, 0], [3, 0], [0, -3], [0, 3]];
            dc.setColor(0x2E9BFF, Graphics.COLOR_TRANSPARENT);
            for (var k = 0; k < o.size(); k++) {
                dc.drawText(w / 2 + o[k][0], h / 2 + o[k][1], bigFont, labels[index], mid);
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, bigFont, labels[index], mid);
        } else {
            var pw = w * 78 / 100;
            var ph = h * 18 / 100;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(w / 2 - pw / 2, h / 2 - ph / 2, pw, ph, ph / 2);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, labelFont, labels[index].toUpper(), mid);
        }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 92 / 100, Graphics.FONT_XTINY, "START to set", mid);
    }
}

class WheelDelegate extends WatchUi.BehaviorDelegate {
    var match as Match;
    var view as WheelView;

    function initialize(m as Match, v as WheelView) {
        BehaviorDelegate.initialize();
        match = m;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_UP) {
            view.turn(-1);
        } else if (key == WatchUi.KEY_DOWN) {
            view.turn(1);
        } else if (key == WatchUi.KEY_ENTER) {
            accept();
        } else {
            return false;
        }
        return true;
    }

    function accept() as Void {
        var n = view.index;
        if (view.kind == :goal) {
            if (n + 1 != match.goal) {
                match.setGoal(n + 1);
            }
        } else if (n != match.cap || !match.capChosen) {
            match.setCap(n);
        }
        (Application.getApp() as VolleyApp).save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);   // the wheel
        WatchUi.popView(WatchUi.SLIDE_DOWN);   // the match menu
        WatchUi.requestUpdate();
    }
}

function pushWheel(match as Match, kind as Symbol, title as String, labels as Array<String>,
                   start as Number) as Void {
    var v = new WheelView(kind, title, labels, start);
    WatchUi.pushView(v, new WheelDelegate(match, v), WatchUi.SLIDE_UP);
}

function pushGoalPicker(match as Match) as Void {
    var l = [] as Array<String>;
    for (var i = 1; i <= Match.MAX_GOAL; i++) {
        l.add("" + i);
    }
    pushWheel(match, :goal, "POINTS TO WIN", l, match.goal - 1);
}

function pushCapPicker(match as Match) as Void {
    var l = [] as Array<String>;
    for (var i = 0; i < 4; i++) {
        l.add(Match.capLabel(i));
    }
    pushWheel(match, :cap, "TIE-BREAK", l, match.cap);
}
