class_name VisualizerTest
extends GdUnitTestSuite

const SCENE := "res://scenes/visualizer.tscn"


func test_step_button_advances_the_status() -> void:
	var runner := scene_runner(SCENE)
	var status := _status_label(runner)
	assert_str(status.text).starts_with("step 0 / ")
	(runner.find_child("StepButton") as Button).pressed.emit()
	assert_str(status.text).starts_with("step 1 / ")


func test_play_advances_steps_over_time() -> void:
	var runner := scene_runner(SCENE)
	(runner.find_child("PlayButton") as Button).pressed.emit()
	var status := _status_label(runner)
	await await_millis(200)
	assert_bool(status.text.begins_with("step 0 /")).is_false()


func test_picking_an_algorithm_resets_the_run() -> void:
	var runner := scene_runner(SCENE)
	(runner.find_child("StepButton") as Button).pressed.emit()
	var picker := runner.find_child("AlgorithmPicker") as OptionButton
	picker.select(1)
	picker.item_selected.emit(1)
	assert_str(_status_label(runner).text).starts_with("step 0 / ")


func test_finished_run_has_no_highlights_left() -> void:
	var runner := scene_runner(SCENE)
	var step_button := runner.find_child("StepButton") as Button
	var status := _status_label(runner)
	while true:
		var counts := status.text.trim_prefix("step ").split(" / ")
		if counts[0] == counts[1]:
			break
		step_button.pressed.emit()
	var board := runner.find_child("Board") as SortBoard
	assert_dict(board.get("_highlights")).is_empty()
	assert_bool(board.get("_done")).is_true()


func _status_label(runner: GdUnitSceneRunner) -> Label:
	return runner.find_child("Status") as Label


func test_bars_leave_room_for_their_position_numbers() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var board := runner.find_child("Board") as SortBoard
	assert_float(board.cell_rect(0).end.y).is_less_equal(board.size.y - SortBoard.POSITION_STRIP)
