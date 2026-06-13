import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Math;
import Toybox.System;

// Best-effort live rep counter based on accelerometer magnitude.
// Counts one rep per up/down swing that crosses both thresholds, with a
// debounce to avoid double-counting noise. The result is only a starting
// point: the user can always correct the count on the set review screen.
class RepCounter {

    private const THRESHOLD_HIGH = 1150; // milli-G
    private const THRESHOLD_LOW = 850;   // milli-G
    private const MIN_INTERVAL_MS = 400;

    private var _count as Number = 0;
    private var _armed as Boolean = false;
    private var _lastRepMs as Number = 0;

    function start() as Void {
        _count = 0;
        _armed = false;
        _lastRepMs = 0;
        Sensor.registerSensorDataListener(method(:onSensorData), {
            :period => 1,
            :accelerometer => { :enabled => true, :sampleRate => 25 }
        });
    }

    function stop() as Void {
        Sensor.unregisterSensorDataListener();
    }

    function getCount() as Number {
        return _count;
    }

    function onSensorData(data as Sensor.SensorData) as Void {
        var accel = data.accelerometerData;
        if (accel == null) {
            return;
        }

        var xs = accel.x;
        var ys = accel.y;
        var zs = accel.z;

        for (var i = 0; i < xs.size(); i++) {
            var mag = Math.sqrt((xs[i] * xs[i] + ys[i] * ys[i] + zs[i] * zs[i]).toFloat());

            if (!_armed && mag > THRESHOLD_HIGH) {
                _armed = true;
            } else if (_armed && mag < THRESHOLD_LOW) {
                var now = System.getTimer();
                if (now - _lastRepMs > MIN_INTERVAL_MS) {
                    _count++;
                    _lastRepMs = now;
                }
                _armed = false;
            }
        }
    }
}
