// Volleyball Score: UP = point blue (left), START = point red (right), DOWN = undo, hold UP = menu, BACK = exit.
// The score is saved after every change, so leaving the app never loses the match.
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class VolleyApp extends Application.AppBase {
    var match as Match = new Match();

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        match.load(Storage.getValue("events"));
    }

    function onStop(state as Dictionary?) as Void {
        save();
    }

    function save() as Void {
        Storage.setValue("events", match.toStorage());
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new VolleyView(match);
        return [view, new VolleyDelegate(match, view)];
    }
}
