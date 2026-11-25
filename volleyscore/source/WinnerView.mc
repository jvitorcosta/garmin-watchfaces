// Full-screen result when the match ends: the winner's colour, a trophy, confetti, the set score.
// START or BACK goes back to the scoreboard; DOWN takes the last point back.
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class WinnerView extends WatchUi.View {
    var match as Match;
    var titleFont as WatchUi.FontResource?;
    var labelFont as WatchUi.FontResource?;

    function initialize(m as Match) {
        View.initialize();
        match = m;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        titleFont = WatchUi.loadResource(Rez.Fonts.BebasTitle) as WatchUi.FontResource;
        labelFont = WatchUi.loadResource(Rez.Fonts.BebasLabel) as WatchUi.FontResource;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var blue = match.sets[0] > match.sets[1];
        var color = blue ? VolleyView.BLUE : VolleyView.RED;
        var dark = blue ? VolleyView.BLUE_DARK : VolleyView.RED_DARK;

        dc.setColor(dark, dark);
        dc.clear();
        dc.setColor(color, color);
        dc.fillRectangle(0, 0, w, h * 66 / 100);

        confetti(dc, w, h);
        trophy(dc, w / 2, h * 21 / 100, w * 10 / 100);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 51 / 100, titleFont, blue ? "BLUE" : "RED",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 73 / 100, labelFont, "WINS THE MATCH",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 85 / 100, labelFont,
                    "SETS " + match.sets[0] + " - " + match.sets[1],
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // A white cup: bowl, stem, base and two handles, `s` is half the cup's width.
    private function trophy(dc as Graphics.Dc, cx as Number, cy as Number, s as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawArc(cx - s, cy - s / 3, s / 2, Graphics.ARC_COUNTER_CLOCKWISE, 90, 270);
        dc.drawArc(cx + s, cy - s / 3, s / 2, Graphics.ARC_COUNTER_CLOCKWISE, 270, 90);
        dc.fillPolygon([[cx - s, cy - s], [cx + s, cy - s], [cx + s * 2 / 3, cy + s / 2],
                        [cx + s / 4, cy + s * 4 / 5], [cx - s / 4, cy + s * 4 / 5],
                        [cx - s * 2 / 3, cy + s / 2]]);
        dc.fillRectangle(cx - s / 8, cy + s * 4 / 5, s / 4, s / 2);
        dc.fillRoundedRectangle(cx - s / 2, cy + s * 4 / 5 + s / 2, s, s / 5, 2);
    }

    // Fixed scatter (same every time) of small white and yellow pieces around the edges.
    private function confetti(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var seed = 7;
        for (var i = 0; i < 26; i++) {
            seed = (seed * 75 + 74) % 65537;
            var x = seed % w;
            seed = (seed * 75 + 74) % 65537;
            var y = seed % (h * 60 / 100);
            // Keep the middle (trophy) clear.
            if (x > w * 30 / 100 && x < w * 70 / 100 && y > h * 8 / 100) {
                continue;
            }
            dc.setColor(i % 3 == 0 ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (i % 2 == 0) {
                dc.fillRectangle(x, y, 7, 4);
            } else {
                dc.fillCircle(x, y, 3);
            }
        }
    }
}

class WinnerDelegate extends WatchUi.BehaviorDelegate {
    var match as Match;

    function initialize(m as Match) {
        BehaviorDelegate.initialize();
        match = m;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_DOWN) {
            match.undo();
            (Application.getApp() as VolleyApp).save();
        } else if (evt.getKey() != WatchUi.KEY_ENTER) {
            return false;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
