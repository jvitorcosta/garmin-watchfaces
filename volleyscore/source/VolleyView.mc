// Split screen: each team's half fills with its colour as it scores (light blue left, red right).
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class VolleyView extends WatchUi.View {
    static const BLUE = 0x2E9BFF;
    static const RED = 0xE5343A;
    static const BLUE_DARK = 0x0B2540;
    static const RED_DARK = 0x3A1215;
    static const BASE = 0.20;

    var match as Match;
    var scoreFont as WatchUi.FontResource?;
    var labelFont as WatchUi.FontResource?;

    function initialize(m as Match) {
        View.initialize();
        match = m;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        scoreFont = WatchUi.loadResource(Rez.Fonts.BebasScore) as WatchUi.FontResource;
        labelFont = WatchUi.loadResource(Rez.Fonts.BebasLabel) as WatchUi.FontResource;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var goal = match.currentTarget();
        // Each half is a dark tint of the team colour that fills up with the team colour as the
        // set goes; at 0-0 only a thin base strip shows who is who.
        fillHalf(dc, 0, BLUE, BLUE_DARK, goal);
        fillHalf(dc, 1, RED, RED_DARK, goal);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(w / 2, h * 22 / 100, w / 2, h);

        drawTeam(dc, 0, w / 4);
        drawTeam(dc, 1, w * 3 / 4);

        // White ribbon on top: which set, and the score that wins it.
        var info;
        if (match.over) {
            info = match.sets[0] > match.sets[1] ? "BLUE WINS" : "RED WINS";
        } else {
            info = "SET " + match.setNumber() + " · " + goal;
        }
        var rw = w * 46 / 100;
        var rh = h * 12 / 100;
        var ry = h * 7 / 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(w / 2 - rw / 2, ry, rw, rh, rh / 2);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, ry + rh / 2, labelFont, info.toUpper(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var prev = "";
        for (var i = 0; i < match.history.size(); i++) {
            prev += (i > 0 ? "  " : "") + match.history[i][0] + "-" + match.history[i][1];
        }
        if (prev.length() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 91 / 100, Graphics.FONT_XTINY, prev,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function fillHalf(dc as Graphics.Dc, team as Number, color as Number, dark as Number,
                              goal as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var x = team == 0 ? 0 : w / 2;
        var half = team == 0 ? w / 2 : w - w / 2;
        dc.setColor(dark, dark);
        dc.fillRectangle(x, 0, half, h);
        var frac = match.pts[team].toFloat() / goal;
        if (frac > 1.0) {
            frac = 1.0;
        }
        var level = BASE + (1.0 - BASE) * frac;   // share of the half's height that is coloured
        var top = h - (h * level).toNumber();
        dc.setColor(color, color);
        dc.fillRectangle(x, top, half, h - top);
    }

    // Set dots (filled = won), big white points, serve marker under the points.
    private function drawTeam(dc as Graphics.Dc, team as Number, cx as Number) as Void {
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < Match.SETS_TO_WIN; i++) {
            var x = cx + (i - 1) * 22;
            if (i < match.sets[team]) {
                dc.fillCircle(x, h * 32 / 100, 7);
            } else {
                dc.drawCircle(x, h * 32 / 100, 7);
            }
        }
        dc.drawText(cx, h * 53 / 100, scoreFont, match.pts[team].toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (match.serve == team && !match.over) {
            dc.fillCircle(cx, h * 77 / 100, 9);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, h * 77 / 100, 9);
        }
    }
}
