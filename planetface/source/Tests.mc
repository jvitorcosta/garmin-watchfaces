// Unit tests for Sky (no device data). Build with --unit-test and run with
// monkeydo <prg> fr255 /t (Windows; -t elsewhere) while the simulator is open.
// Reference distances: the same elements in Python, checked against known events.
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
function testBodyFollowsWeekday(logger as Test.Logger) as Boolean {
    Test.assertEqual(Sky.body(1), Sky.SUN);    // Sunday
    Test.assertEqual(Sky.body(2), Sky.MOON);   // Monday
    Test.assertEqual(Sky.NAMES[Sky.body(3)], "MARS");
    Test.assertEqual(Sky.NAMES[Sky.body(7)], "SATURN");
    return true;
}

(:test)
function testDaysFromCivil(logger as Test.Logger) as Boolean {
    Test.assertEqual(Sky.daysFromCivil(1970, 1, 1), 0);
    Test.assertEqual(Sky.daysFromCivil(2000, 3, 1), 11017);
    Test.assertEqual(Sky.daysFromCivil(1969, 12, 31), -1);
    return true;
}

(:test)
function testMet(logger as Test.Logger) as Boolean {
    Test.assertEqual(Sky.met(1969, 7, 20), 0);
    Test.assertEqual(Sky.met(2026, 10, 26), 20917);
    Test.assertEqual(Sky.met(2024, 2, 29), 19947);
    return true;
}

function near(got as Double, want as Double, tol as Double) as Boolean {
    var ok = (got - want).abs() <= tol;
    if (!ok) {
        System.println("got " + got + ", want " + want + " +/- " + tol);
    }
    return ok;
}

(:test)
function testPlanetDistances(logger as Test.Logger) as Boolean {
    var au = Sky.AU_KM;
    Test.assert(near(Sky.distanceKm(5, 1792800000) / au, 0.2730d, 0.002d));   // Venus, closest, 2026-10-24
    Test.assert(near(Sky.distanceKm(6, 1791072000) / au, 8.4344d, 0.01d));    // Saturn at opposition, 2026-10-04
    Test.assert(near(Sky.distanceKm(2, 1736640000) / au, 0.6423d, 0.003d));   // Mars at opposition, 2025-01-12
    Test.assert(near(Sky.distanceKm(Sky.SUN, 1792929600) / au, 0.9944d, 0.001d));
    return true;
}

(:test)
function testMoonDistance(logger as Test.Logger) as Boolean {
    Test.assert(near(Sky.distanceKm(Sky.MOON, 1762380000), 356932.0d, 400.0d));   // perigee, 2025-11-05
    Test.assert(near(Sky.distanceKm(Sky.MOON, 1763596800), 406610.0d, 400.0d));   // apogee, 2025-11-20
    return true;
}

(:test)
function testLightText(logger as Test.Logger) as Boolean {
    Test.assertEqual(Sky.lightText(384400.0d), "1.3s");
    Test.assertEqual(Sky.lightText(148800000.0d), "8m 16s");
    Test.assertEqual(Sky.lightText(1261800000.0d), "1h 10m");
    return true;
}

(:test)
function testDistText(logger as Test.Logger) as Boolean {
    Test.assertEqual(Sky.distText(384400.0d), "384k km");
    Test.assertEqual(Sky.distText(219700000.0d), "219M km");
    Test.assertEqual(Sky.distText(1261800000.0d), "1.26B km");
    return true;
}
