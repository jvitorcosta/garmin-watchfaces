// Planet face: a Forerunner 255 watch face showing the body today's weekday is named after.
// Sky does the calendar and orbit maths, PlanetView draws the screen.
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PlanetApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new PlanetView()];
    }
}
