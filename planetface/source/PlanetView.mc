import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// true: the simulator steps through the 7 bodies, one per minute. Never ship it on.
const DEMO = false;

// Layout (mockup "A + B, week"), top to bottom on black: the weekday and date; the time, big;
// MET (days since Apollo 11) in gold; then today's body filling the bottom of the screen, with
// the step goal as a gold arc along its edge and a black telemetry box over it: the body's name,
// light delay, distance, battery as fuel, steps. Everything is read and worked out once a minute.
class PlanetView extends WatchUi.WatchFace {
    const CX = 130;
    const PLANET_TOP = 117;     // the picture covers screen rows 117-259
    const ARC_Y = 330;          // the disc's centre (off screen) and the arc's radius, just outside it
    const ARC_R = 213;
    const ARC_FROM = 125;       // degrees, counter-clockwise from 3 o'clock: the visible part of the edge
    const ARC_SPAN = 70;
    const GOLD = 0xFFAA55;
    const TEAL = 0x55AAAA;
    const GREY = 0xAAAAAA;
    const DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    // A few fixed stars in the black above the planet
    const STARS = [[48, 80], [214, 70], [230, 110], [28, 118], [160, 18], [96, 22], [196, 40], [62, 44]];

    private var _fTime as Graphics.FontType;
    private var _fSmall as Graphics.FontType;
    private var _fTiny as Graphics.FontType;
    private var _planet as WatchUi.BitmapResource or Null;   // only today's body is loaded
    private var _planetBody as Number = -1;
    private var _minute as Number = -1;   // -1: work everything out on the next update

    // What refresh() worked out, ready to draw
    private var _body as Number = 0;
    private var _date as String = "";
    private var _met as String = "";
    private var _light as String = "--";
    private var _dist as String = "--";
    private var _fuel as String = "--";
    private var _steps as String = "--";
    private var _goal as Float = 0.0;

    function initialize() {
        WatchFace.initialize();
        _fTime = WatchUi.loadResource(Rez.Fonts.VtTime) as Graphics.FontType;
        _fSmall = WatchUi.loadResource(Rez.Fonts.VtSmall) as Graphics.FontType;
        _fTiny = WatchUi.loadResource(Rez.Fonts.VtTiny) as Graphics.FontType;
    }

    function onShow() as Void {
        _minute = -1;
    }

    function onExitSleep() as Void {
        _minute = -1;
    }

    function onUpdate(dc as Dc) as Void {
        var clock = System.getClockTime();
        if (clock.min != _minute) {
            _minute = clock.min;
            refresh(clock);
        }
        if (_planet == null || _planetBody != _body) {
            _planet = null;   // free yesterday's before loading today's
            _planet = WatchUi.loadResource(planetRez(_body)) as WatchUi.BitmapResource;
            _planetBody = _body;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        for (var i = 0; i < STARS.size(); i++) {
            var s = STARS[i] as Array<Number>;
            dc.drawPoint(s[0], s[1]);
        }
        dc.drawBitmap(0, PLANET_TOP, _planet);

        // The step goal along the planet's edge: a dark track, gold as far as today's steps reach
        dc.setPenWidth(3);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(CX, ARC_Y, ARC_R, Graphics.ARC_CLOCKWISE, ARC_FROM, ARC_FROM - ARC_SPAN);
        if (_goal > 0.0) {
            dc.setColor(GOLD, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(CX, ARC_Y, ARC_R, Graphics.ARC_CLOCKWISE, ARC_FROM,
                       ARC_FROM - (ARC_SPAN * _goal).toNumber() - 1);
        }
        dc.setPenWidth(1);

        // Date, time, MET
        dc.setColor(GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 28, _fTiny, _date, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 38, _fTime, clockText(clock), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(GOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 93, _fSmall, _met, Graphics.TEXT_JUSTIFY_CENTER);

        // The telemetry box over the planet
        var bx = 66;
        var by = 138;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(bx, by, 128, 78);
        dc.setColor(0x005555, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(bx, by, 128, 78);
        dc.setColor(GOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bx + 7, by + 1, _fSmall, "> " + (Sky.NAMES[_body] as String), Graphics.TEXT_JUSTIFY_LEFT);
        row(dc, bx, by + 16, "LIGHT", _light);
        row(dc, bx, by + 30, "DIST", _dist);
        row(dc, bx, by + 44, "FUEL", _fuel);
        row(dc, bx, by + 58, "STEPS", _steps);
    }

    // A telemetry row: the label in teal on the left, its value in white on the right.
    private function row(dc as Dc, bx as Number, y as Number, label as String, value as String) as Void {
        dc.setColor(TEAL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bx + 7, y, _fSmall, label, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bx + 121, y, _fSmall, value, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    private function clockText(clock as System.ClockTime) as String {
        var h = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12 == 0 ? 12 : h % 12;
        }
        return h.format("%02d") + ":" + clock.min.format("%02d");
    }

    // Works out the day's body, the date line, MET, the body's light delay and distance right now,
    // the battery and the steps.
    private function refresh(clock as System.ClockTime) as Void {
        var now = Time.now();
        var g = Gregorian.info(now, Time.FORMAT_SHORT);
        var dow = g.day_of_week as Number;
        var month = g.month as Number;
        _body = DEMO ? clock.min % 7 : Sky.body(dow);
        _date = (DAYS[dow - 1] as String) + " " + g.day + " " + (MONTHS[month - 1] as String);
        _met = "MET " + Sky.met(g.year, month, g.day) + "d";
        var km = Sky.distanceKm(_body, now.value());
        _light = Sky.lightText(km);
        _dist = Sky.distText(km);
        _fuel = System.getSystemStats().battery.toNumber() + "%";
        var act = ActivityMonitor.getInfo();
        var steps = act.steps;
        var goal = act.stepGoal;
        _steps = steps != null ? steps.toString() : "--";
        _goal = steps != null && goal != null && goal > 0 ? (steps > goal ? 1.0 : steps.toFloat() / goal) : 0.0;
    }

    private function planetRez(b as Number) as ResourceId {
        var ids = [Rez.Drawables.Planet0, Rez.Drawables.Planet1, Rez.Drawables.Planet2, Rez.Drawables.Planet3,
                   Rez.Drawables.Planet4, Rez.Drawables.Planet5, Rez.Drawables.Planet6];
        return ids[b] as ResourceId;
    }
}
