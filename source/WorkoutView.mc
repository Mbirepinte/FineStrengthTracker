import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Timer;

// Workout state machine, mirroring the native Garmin strength flow:
//
//   ACTIVE      -> set in progress, timer running
//     BACK      -> REPS_EDIT (stop set timer, show reps)
//   REPS_EDIT   -> adjust reps with UP/DOWN
//     START     -> WEIGHT_EDIT
//   WEIGHT_EDIT -> adjust weight with UP/DOWN
//     START     -> EXERCISE_EDIT
//   EXERCISE_EDIT -> pick exercise with UP/DOWN
//     START     -> log the set, start rest timer -> REST
//   REST        -> rest timer running
//     BACK      -> new set starts -> ACTIVE
enum {
    STATE_ACTIVE,
    STATE_REPS_EDIT,
    STATE_WEIGHT_EDIT,
    STATE_EXERCISE_EDIT,
    STATE_REST
}

class WorkoutView extends WatchUi.View {

    private var _exerciseIndex as Number;
    private var _catalog as Array<ExerciseDef>;
    private var _session as ActivityRecording.Session?;

    private var _state as Number = STATE_ACTIVE;

    private var _reps as Number = 8;
    private var _weight as Number = 20; // kg
    private var _setNumber as Number = 0;

    private var _activeSeconds as Number = 0;
    private var _restSeconds as Number = 0;
    private var _timer as Timer.Timer?;

    private var _setCategoryField as FitContributor.Field?;
    private var _setNameField as FitContributor.Field?;
    private var _setRepsField as FitContributor.Field?;
    private var _setWeightField as FitContributor.Field?;
    private var _setTypeField as FitContributor.Field?;

    function initialize(exerciseIndex as Number) {
        View.initialize();
        _catalog = ExerciseData.getCatalog();
        _exerciseIndex = exerciseIndex;
    }

    function getExercise() as ExerciseDef {
        return _catalog[_exerciseIndex];
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        if (_session == null) {
            startSession();
        }
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(method(:onTimerTick), 1000, true);
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        if (_state == STATE_ACTIVE) {
            _activeSeconds++;
        } else if (_state == STATE_REST) {
            _restSeconds++;
        }
        WatchUi.requestUpdate();
    }

    function startSession() as Void {
        _session = ActivityRecording.createSession({
            :name => "Strength",
            :sport => ActivityRecording.SPORT_TRAINING,
            :subSport => ActivityRecording.SUB_SPORT_STRENGTH_TRAINING
        });

        // V0: custom fields written to the default "record" message.
        // TODO: revisit mapping to the FIT "set" message (mesgType 225)
        // once the basic recording flow is validated.
        _setCategoryField = _session.createField(
            "exercise_category", 0, FitContributor.DATA_TYPE_UINT16, {}
        );
        _setNameField = _session.createField(
            "exercise_name", 1, FitContributor.DATA_TYPE_UINT16, {}
        );
        _setRepsField = _session.createField(
            "reps", 2, FitContributor.DATA_TYPE_UINT16, {}
        );
        _setWeightField = _session.createField(
            "weight", 3, FitContributor.DATA_TYPE_UINT16, {:units => "kg"}
        );
        _setTypeField = _session.createField(
            "set_type", 4, FitContributor.DATA_TYPE_UINT8, {}
        );

        _session.start();
    }

    // ---- Button handlers (called from WorkoutDelegate) ----

    // BACK button
    function onBackPressed() as Void {
        if (_state == STATE_ACTIVE) {
            // End of active set -> review reps
            _state = STATE_REPS_EDIT;
        } else if (_state == STATE_REST) {
            // Rest over -> start a new active set
            _activeSeconds = 0;
            _state = STATE_ACTIVE;
        }
        WatchUi.requestUpdate();
    }

    // START/SELECT button
    function onStartPressed() as Void {
        if (_state == STATE_REPS_EDIT) {
            _state = STATE_WEIGHT_EDIT;
        } else if (_state == STATE_WEIGHT_EDIT) {
            _state = STATE_EXERCISE_EDIT;
        } else if (_state == STATE_EXERCISE_EDIT) {
            logSet();
            _restSeconds = 0;
            _state = STATE_REST;
        }
        WatchUi.requestUpdate();
    }

    // UP button
    function onUpPressed() as Void {
        if (_state == STATE_REPS_EDIT) {
            _reps++;
        } else if (_state == STATE_WEIGHT_EDIT) {
            _weight += 5;
        } else if (_state == STATE_EXERCISE_EDIT) {
            _exerciseIndex = (_exerciseIndex + 1) % _catalog.size();
        }
        WatchUi.requestUpdate();
    }

    // DOWN button
    function onDownPressed() as Void {
        if (_state == STATE_REPS_EDIT) {
            if (_reps > 1) { _reps--; }
        } else if (_state == STATE_WEIGHT_EDIT) {
            if (_weight >= 5) { _weight -= 5; }
        } else if (_state == STATE_EXERCISE_EDIT) {
            _exerciseIndex = (_exerciseIndex - 1 + _catalog.size()) % _catalog.size();
        }
        WatchUi.requestUpdate();
    }

    // Records one completed set with the current reps/weight/exercise.
    private function logSet() as Void {
        if (_session == null) {
            return;
        }

        var ex = getExercise();
        _setCategoryField.setData(ex.category);
        _setNameField.setData(ex.name);
        _setRepsField.setData(_reps);
        _setWeightField.setData(_weight);
        _setTypeField.setData(1); // 1 = active set (0 = rest)

        _setNumber++;
    }

    function finishWorkout() as Void {
        if (_session != null && _session.isRecording()) {
            _session.stop();
            _session.save();
            _session = null;
        }
    }

    function discardWorkout() as Void {
        if (_session != null) {
            _session.stop();
            _session.discard();
            _session = null;
        }
    }

    private function formatTime(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%02d") + ":" + s.format("%02d");
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var ex = getExercise();

        dc.drawText(w / 2, 15, Graphics.FONT_SMALL, ex.label,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(w / 2, h * 0.18, Graphics.FONT_TINY,
            "Set " + (_setNumber + 1).toString(), Graphics.TEXT_JUSTIFY_CENTER);

        if (_state == STATE_ACTIVE) {
            dc.drawText(w / 2, h * 0.40, Graphics.FONT_NUMBER_MEDIUM,
                formatTime(_activeSeconds), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 0.65, Graphics.FONT_SMALL,
                "Set in progress...", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h - 20, Graphics.FONT_XTINY,
                "BACK: end set", Graphics.TEXT_JUSTIFY_CENTER);

        } else if (_state == STATE_REPS_EDIT) {
            dc.drawText(w / 2, h * 0.30, Graphics.FONT_SMALL,
                "Reps", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 0.50, Graphics.FONT_NUMBER_MEDIUM,
                _reps.toString(), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h - 20, Graphics.FONT_XTINY,
                "UP/DOWN: edit  |  START: next", Graphics.TEXT_JUSTIFY_CENTER);

        } else if (_state == STATE_WEIGHT_EDIT) {
            dc.drawText(w / 2, h * 0.30, Graphics.FONT_SMALL,
                "Weight", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 0.50, Graphics.FONT_NUMBER_MEDIUM,
                _weight.toString() + " kg", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h - 20, Graphics.FONT_XTINY,
                "UP/DOWN: edit  |  START: next", Graphics.TEXT_JUSTIFY_CENTER);

        } else if (_state == STATE_EXERCISE_EDIT) {
            dc.drawText(w / 2, h * 0.30, Graphics.FONT_SMALL,
                "Exercise", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 0.50, Graphics.FONT_MEDIUM,
                ex.label, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h - 20, Graphics.FONT_XTINY,
                "UP/DOWN: change  |  START: confirm", Graphics.TEXT_JUSTIFY_CENTER);

        } else if (_state == STATE_REST) {
            dc.drawText(w / 2, h * 0.30, Graphics.FONT_SMALL,
                "Rest", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 0.50, Graphics.FONT_NUMBER_MEDIUM,
                formatTime(_restSeconds), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h - 20, Graphics.FONT_XTINY,
                "BACK: start next set", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
