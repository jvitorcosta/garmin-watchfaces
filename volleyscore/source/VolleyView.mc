// Split screen: each team's half fills with its colour as it scores (light blue left, red right).
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class VolleyView extends WatchUi.View {
    static const BLUE = 0x2E9BFF;
    static const RED = 0xE5343A;
    static const BLUE_DARK = 0x0B2540;
    static const RED_DARK = 0x3A1215;
    static const BASE = 0.08;

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

        drawSpine(dc, w, h);
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

    // Down the divider, one dot per point of this set, oldest at the top and on the side of the team
    // that scored it, so a run of points shows as a stack on one side. Shows the last 12.
    private function drawSpine(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var log = match.setLog;
        var n = log.size() > 12 ? 12 : log.size();
        var first = log.size() - n;
        for (var i = 0; i < n; i++) {
            var team = log[first + i];
            var x = w / 2 + (team == 0 ? -9 : 9);
            var y = h * 29 / 100 + i * 11;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, 4);
            dc.setColor(team == 0 ? BLUE_DARK : RED_DARK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(x, y, 4);
        }
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
        // A dark outline around the white digits keeps them readable on any amount of fill.
        var txt = match.pts[team].toString();
        var dark = team == 0 ? BLUE_DARK : RED_DARK;
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        var o = [[-3, 0], [3, 0], [0, -3], [0, 3], [-2, -2], [2, -2], [-2, 2], [2, 2]];
        for (var k = 0; k < o.size(); k++) {
            dc.drawText(cx + o[k][0], h * 53 / 100 + o[k][1], scoreFont, txt, just);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 53 / 100, scoreFont, txt, just);
        if (match.serve == team && !match.over) {
            dc.fillCircle(cx, h * 77 / 100, 9);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, h * 77 / 100, 9);
        }
    }
}
