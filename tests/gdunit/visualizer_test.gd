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


func _status_label(runner: GdUnitSceneRunner) -> Label:
	for label in runner.scene().find_children("*", "Label", true, false):
		if label.text.begins_with("step "):
			return label
	return null
