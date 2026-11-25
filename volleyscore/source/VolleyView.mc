// Split screen: light blue left team, red right team, big white points, set dots on top.
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class VolleyView extends WatchUi.View {
    static const BLUE = 0x2E9BFF;
    static const RED = 0xE5343A;

    var match as Match;

    function initialize(m as Match) {
        View.initialize();
        match = m;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, BLUE);
        dc.clear();
        dc.setColor(RED, RED);
        dc.fillRectangle(w / 2, 0, w - w / 2, h);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(w / 2, h * 12 / 100, w / 2, h * 88 / 100);

        drawTeam(dc, 0, w / 4);
        drawTeam(dc, 1, w * 3 / 4);

        var info;
        if (match.over) {
            info = match.sets[0] > match.sets[1] ? "BLUE WINS" : "RED WINS";
        } else {
            info = "SET " + match.setNumber() + " · " + match.currentTarget();
        }
        var small = Graphics.FONT_XTINY;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 10 / 100, small, info,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var prev = "";
        for (var i = 0; i < match.history.size(); i++) {
            prev += (i > 0 ? "  " : "") + match.history[i][0] + "-" + match.history[i][1];
        }
        if (prev.length() > 0) {
            dc.drawText(w / 2, h * 91 / 100, small, prev,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
                dc.fillCircle(x, h * 24 / 100, 7);
            } else {
                dc.drawCircle(x, h * 24 / 100, 7);
            }
        }
        dc.drawText(cx, h * 47 / 100, pointsFont(), match.pts[team].toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (match.serve == team && !match.over) {
            dc.fillCircle(cx, h * 74 / 100, 9);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, h * 74 / 100, 9);
        }
    }

    // A bold vector font when the watch has them, else the biggest built-in number font.
    private function pointsFont() as Graphics.FontType {
        if (Graphics has :getVectorFont) {
            var f = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoBold", "Roboto"],
                                            :size => 92});
            if (f != null) {
                return f;
            }
        }
        return Graphics.FONT_NUMBER_THAI_HOT;
    }
}
