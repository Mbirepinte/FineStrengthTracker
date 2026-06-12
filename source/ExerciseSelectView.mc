import Toybox.Lang;
import Toybox.WatchUi;

class ExerciseSelectView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "FineStrength"});

        var catalog = ExerciseData.getCatalog();
        for (var i = 0; i < catalog.size(); i++) {
            var ex = catalog[i];
            addItem(new MenuItem(ex.label, null, i.toString(), {}));
        }
    }
}

class ExerciseSelectDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var index = (item.getId() as String).toNumber();

        var workoutView = new WorkoutView(index);
        WatchUi.pushView(workoutView, new WorkoutDelegate(workoutView), WatchUi.SLIDE_LEFT);
    }
}
