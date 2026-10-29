import Toybox.Lang;
import Toybox.Math;

// The calendar and the sky, without device data (unit-tested in Tests.mc).
// Bodies are numbered by Garmin's day_of_week - 1: 0 Sun, 1 Moon, 2 Mars, 3 Mercury, 4 Jupiter,
// 5 Venus, 6 Saturn (Sunday to Saturday, the bodies the weekdays are named after).
module Sky {
    const NAMES = ["SUN", "MOON", "MARS", "MERCURY", "JUPITER", "VENUS", "SATURN"];
    const SUN = 0;
    const MOON = 1;
    const AU_KM = 149597870.7d;
    const LIGHT_KM_S = 299792.458d;
    const DEG = 0.017453292519943295d;   // radians a degree

    // JPL's (Standish) mean orbital elements at J2000 and their change a century, good from 1800
    // to 2050: a (AU), e, I, L, longitude of perihelion, longitude of the node (degrees), then the
    // six rates. Indexed by body; the Sun and the Moon have none (Earth's is EARTH).
    const EARTH = [1.00000261d, 0.01671123d, -0.00001531d, 100.46457166d, 102.93768193d, 0.0d,
                   0.00000562d, -0.00004392d, -0.01294668d, 35999.37244981d, 0.32327364d, 0.0d];
    const ELEMENTS = [
        null,
        null,
        [1.52371034d, 0.09339410d, 1.84969142d, -4.55343205d, -23.94362959d, 49.55953891d,
         0.00001847d, 0.00007882d, -0.00813131d, 19140.30268499d, 0.44441088d, -0.29257343d],
        [0.38709927d, 0.20563593d, 7.00497902d, 252.25032350d, 77.45779628d, 48.33076593d,
         0.00000037d, 0.00001906d, -0.00594749d, 149472.67411175d, 0.16047689d, -0.12534081d],
        [5.20288700d, 0.04838624d, 1.30439695d, 34.39644051d, 14.72847983d, 100.47390909d,
         -0.00011607d, -0.00013253d, -0.00183714d, 3034.74612775d, 0.21252668d, 0.20469106d],
        [0.72333566d, 0.00677672d, 3.39467605d, 181.97909950d, 131.60246718d, 76.67984255d,
         0.00000390d, -0.00004107d, -0.00078890d, 58517.81538729d, 0.00268329d, -0.27769418d],
        [9.53667594d, 0.05386179d, 2.48599187d, 49.95424423d, 92.59887831d, 113.66242448d,
         -0.00125060d, -0.00050991d, 0.00193609d, 1222.49362201d, -0.41897216d, -0.28867794d]];

    // Today's body from Garmin's day_of_week (1 = Sunday).
    function body(dow as Number) as Number {
        return (dow - 1) % 7;
    }

    // Days since 1970-01-01 of a calendar date (Howard Hinnant's days_from_civil).
    function daysFromCivil(y as Number, m as Number, d as Number) as Number {
        if (m <= 2) {
            y -= 1;
        }
        var era = (y >= 0 ? y : y - 399) / 400;
        var yoe = y - era * 400;
        var doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
        var doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
        return era * 146097 + doe - 719468;
    }

    // Mission elapsed time: whole days since Apollo 11 landed (1969-07-20), on the local date.
    function met(y as Number, m as Number, d as Number) as Number {
        return daysFromCivil(y, m, d) - daysFromCivil(1969, 7, 20);
    }

    // Distance from Earth to `b` at `unix` seconds, in km.
    function distanceKm(b as Number, unix as Number) as Double {
        var days = unix.toDouble() / 86400.0d - 10957.5d;   // since J2000 (2000-01-01 12:00)
        if (b == MOON) {
            return moonKm(days);
        }
        var t = days / 36525.0d;
        var e = helio(EARTH, t);
        if (b == SUN) {
            return Math.sqrt(e[0] * e[0] + e[1] * e[1] + e[2] * e[2]) * AU_KM;
        }
        var p = helio(ELEMENTS[b] as Array<Double>, t);
        var dx = p[0] - e[0];
        var dy = p[1] - e[1];
        var dz = p[2] - e[2];
        return Math.sqrt(dx * dx + dy * dy + dz * dz) * AU_KM;
    }

    // Heliocentric ecliptic position (AU) from mean elements `el` at `t` centuries after J2000.
    function helio(el as Array<Double>, t as Double) as Array<Double> {
        var a = el[0] + el[6] * t;
        var ecc = el[1] + el[7] * t;
        var inc = (el[2] + el[8] * t) * DEG;
        var l = el[3] + el[9] * t;
        var peri = el[4] + el[10] * t;
        var node = el[5] + el[11] * t;
        var mean = l - peri;
        mean = (mean - 360.0d * Math.floor(mean / 360.0d)) * DEG;
        var om = (peri - node) * DEG;
        node = node * DEG;
        var ea = mean + ecc * Math.sin(mean);   // Kepler's equation by Newton's method
        for (var i = 0; i < 6; i++) {
            ea -= (ea - ecc * Math.sin(ea) - mean) / (1.0d - ecc * Math.cos(ea));
        }
        var xp = a * (Math.cos(ea) - ecc);
        var yp = a * Math.sqrt(1.0d - ecc * ecc) * Math.sin(ea);
        var co = Math.cos(om);
        var so = Math.sin(om);
        var cn = Math.cos(node);
        var sn = Math.sin(node);
        var ci = Math.cos(inc);
        var si = Math.sin(inc);
        return [(co * cn - so * sn * ci) * xp + (-so * cn - co * sn * ci) * yp,
                (co * sn + so * cn * ci) * xp + (-so * sn + co * cn * ci) * yp,
                so * si * xp + co * si * yp] as Array<Double>;
    }

    // The Moon's distance (km) `days` after J2000: the biggest terms of Meeus's series (within ~300 km).
    function moonKm(days as Double) as Double {
        var d = (297.8501921d + 12.19074912d * days) * DEG;   // elongation
        var ms = (357.5291092d + 0.98560028d * days) * DEG;   // the Sun's anomaly
        var mm = (134.9633964d + 13.06499295d * days) * DEG;  // the Moon's anomaly
        return 385000.56d - 20905.355d * Math.cos(mm) - 3699.111d * Math.cos(2 * d - mm)
               - 2955.968d * Math.cos(2 * d) - 569.925d * Math.cos(2 * mm) + 48.888d * Math.cos(ms)
               + 246.158d * Math.cos(2 * d - 2 * mm) - 152.138d * Math.cos(2 * d - ms - mm)
               - 170.733d * Math.cos(2 * d + mm) - 204.586d * Math.cos(2 * d - ms)
               - 129.620d * Math.cos(ms - mm) + 108.743d * Math.cos(d) + 104.755d * Math.cos(ms + mm);
    }

    // How long light takes over `km`: "1.3s", "8m 18s", "1h 10m".
    function lightText(km as Double) as String {
        var s = km / LIGHT_KM_S;
        if (s < 60.0d) {
            return s.format("%.1f") + "s";
        }
        var whole = s.toNumber();
        if (whole < 3600) {
            return (whole / 60) + "m " + (whole % 60) + "s";
        }
        return (whole / 3600) + "h " + (whole % 3600 / 60) + "m";
    }

    // A distance in km, short: "384k km", "220M km", "1.26B km".
    function distText(km as Double) as String {
        if (km < 1.0e6d) {
            return (km / 1000.0d).toNumber() + "k km";
        }
        if (km < 1.0e9d) {
            return (km / 1.0e6d).toNumber() + "M km";
        }
        return (km / 1.0e9d).format("%.2f") + "B km";
    }
}
