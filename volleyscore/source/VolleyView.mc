import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class VolleyView extends WatchUi.View {
    var match as Match;

    function initialize(m as Match) {
        View.initialize();
        match = m;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        drawTeam(dc, 0, "US", h * 20 / 100, h * 34 / 100, Graphics.COLOR_GREEN);
        drawTeam(dc, 1, "THEM", h * 80 / 100, h * 68 / 100, Graphics.COLOR_ORANGE);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 15 / 100, h / 2, w * 85 / 100, h / 2);

        var info;
        if (match.over) {
            info = match.sets[0] > match.sets[1] ? "WE WIN" : "THEY WIN";
        } else {
            info = "SET " + match.setNumber() + " to " + match.currentTarget();
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 - 12, Graphics.FONT_XTINY, info,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var prev = "";
        for (var i = 0; i < match.history.size(); i++) {
            prev += (i > 0 ? " " : "") + match.history[i][0] + "-" + match.history[i][1];
        }
        if (prev.length() > 0) {
            dc.drawText(w / 2, h / 2 + 12, Graphics.FONT_XTINY, prev,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Name and sets-won tally, points big below it, serve dot beside the points.
    private function drawTeam(dc as Graphics.Dc, team as Number, label as String,
                              labelY as Number, pointsY as Number, color as Number) as Void {
        var w = dc.getWidth();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, labelY, Graphics.FONT_XTINY, label + "  sets " + match.sets[team],
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, pointsY, Graphics.FONT_NUMBER_HOT, match.pts[team].toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (match.serve == team && !match.over) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(w * 20 / 100, pointsY, 8);
        }
    }
}
