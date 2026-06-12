import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WorkoutView;

    function initialize(view as WorkoutView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP
    function onPreviousPage() as Boolean {
        _view.onUpPressed();
        return true;
    }

    // DOWN
    function onNextPage() as Boolean {
        _view.onDownPressed();
        return true;
    }

    // START/SELECT
    function onSelect() as Boolean {
        _view.onStartPressed();
        return true;
    }

    // BACK
    function onBack() as Boolean {
        _view.onBackPressed();
        return true;
    }

    // MENU: end and save the workout, return to exercise list
    function onMenu() as Boolean {
        _view.finishWorkout();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
