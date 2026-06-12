import Toybox.Lang;

// Predefined exercise catalog for V0.
// category / name values map to the FIT SDK "exercise_category" and
// "exercise_name" enums (Profile.xlsx). The values below cover the most
// common lifts; double-check against the FIT SDK profile if Garmin Connect
// shows "Unknown" for an exercise.
class ExerciseDef {
    var label as String;
    var category as Number; // exercise_category enum
    var name as Number;     // exercise_name enum (within the category)

    function initialize(label as String, category as Number, name as Number) {
        self.label = label;
        self.category = category;
        self.name = name;
    }
}

class ExerciseData {

    static function getCatalog() as Array<ExerciseDef> {
        return [
            new ExerciseDef("Squat",          28, 0), // BARBELL_BACK_SQUAT
            new ExerciseDef("Bench Press",     0, 0), // BARBELL_BENCH_PRESS
            new ExerciseDef("Deadlift",        8, 0), // CONVENTIONAL_DEADLIFT
            new ExerciseDef("Shoulder Press", 24, 0), // BARBELL_SHOULDER_PRESS
            new ExerciseDef("Pull Up",        21, 0), // PULL_UP
            new ExerciseDef("Push Up",        22, 0), // PUSH_UP
            new ExerciseDef("Barbell Row",    23, 0), // BARBELL_ROW
            new ExerciseDef("Lunge",          17, 0), // LUNGE
            new ExerciseDef("Biceps Curl",     7, 0), // BICEPS_CURL
        ] as Array<ExerciseDef>;
    }
}
