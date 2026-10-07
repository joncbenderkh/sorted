class_name PlayTest
extends GdUnitTestSuite

const SCENE := "res://scenes/visualizer.tscn"
const FREE_PLAY := 1
const GUIDED := 2
const INSERTION_SORT := 1

var _cache0 := SortState.cache_location(0)


func test_dragging_a_bar_onto_another_swaps_them_in_free_play() -> void:
	var runner := await _start(FREE_PLAY)
	var state := _state(runner)
	var first: Variant = state.get_value(0)
	var second: Variant = state.get_value(1)
	_drag(runner, 0, 1)
	assert_that(state.get_value(0)).is_equal(second)
	assert_that(state.get_value(1)).is_equal(first)
	assert_str(_text(runner, "Status")).starts_with("moves 1 / par ")


func test_dropping_into_an_occupied_cache_slot_is_refused_and_explained() -> void:
	var runner := await _start(FREE_PLAY)
	var state := _state(runner)
	_drag(runner, 0, _cache0)
	var held: Variant = state.get_value(_cache0)
	var second: Variant = state.get_value(1)
	_drag(runner, 1, _cache0)
	assert_str(_text(runner, "Message")).contains("occupied")
	assert_that(state.get_value(1)).is_equal(second)
	assert_that(state.get_value(_cache0)).is_equal(held)
	assert_str(_text(runner, "Status")).starts_with("moves 1 / ")


func test_guided_refuses_a_move_that_is_not_the_next_one() -> void:
	var runner := await _start(GUIDED)
	var state := _state(runner)
	var first: Variant = state.get_value(0)
	_drag(runner, 0, 1)
	assert_str(_text(runner, "Message")).is_equal("not the algorithm's next move")
	assert_that(state.get_value(0)).is_equal(first)
	assert_str(_text(runner, "Status")).starts_with("moves 0 / ")


func test_guided_accepts_the_next_move_and_the_hint_shows_it() -> void:
	var runner := await _start(GUIDED)
	assert_str(_text(runner, "Message")).starts_with("Goal: ")
	runner.find_child("HintButton").pressed.emit()
	assert_str(_text(runner, "Message")).starts_with("Hint: ")
	var highlights: Dictionary = _board(runner).get("_highlights")
	assert_array(highlights.keys()).contains_exactly_in_any_order([1, _cache0])
	_drag(runner, 1, _cache0)
	assert_str(_text(runner, "Message")).starts_with("Goal: ")
	assert_str(_text(runner, "Status")).starts_with("moves 1 / ")


func test_dragging_does_nothing_while_watching() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var state := _state(runner)
	var first: Variant = state.get_value(0)
	_drag(runner, 0, 1)
	assert_that(state.get_value(0)).is_equal(first)


func test_following_the_algorithm_by_hand_finishes_the_run() -> void:
	var runner := await _start(GUIDED, 8)
	var session: PlaySession = runner.scene().get("_session")
	var values: Array[int] = []
	for index in session.state.array_size():
		values.append(session.state.get_value(index))
	for step in InsertionSort.new().sort(values, 1):
		if step.type != SortStep.Type.COMPARE and not session.is_finished():
			_drag(runner, step.first, step.second)
	assert_bool(session.is_finished()).is_true()
	assert_str(_text(runner, "Status")).starts_with("Sorted in ")


func _start(mode: int, items: int = 0) -> GdUnitSceneRunner:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	if items > 0:
		(runner.scene().get("_items_slider") as HSlider).value = items
	var algorithm := runner.find_child("AlgorithmPicker") as OptionButton
	algorithm.select(INSERTION_SORT)
	algorithm.item_selected.emit(INSERTION_SORT)
	var picker := runner.find_child("ModePicker") as OptionButton
	picker.select(mode)
	picker.item_selected.emit(mode)
	await runner.simulate_frames(2)
	return runner


## Feeds the board the mouse events of a drag. Calling _gui_input directly
## keeps this independent of the display server, which drops simulated mouse
## input when Godot runs headless.
func _drag(runner: GdUnitSceneRunner, from_location: int, to_location: int) -> void:
	var board := _board(runner)
	var from := board.cell_rect(from_location).get_center()
	var to := board.cell_rect(to_location).get_center()
	board._gui_input(_button_event(from, true))
	board._gui_input(_motion_event(to))
	board._gui_input(_button_event(to, false))


func _button_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func _motion_event(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	return event


func _board(runner: GdUnitSceneRunner) -> SortBoard:
	return runner.find_child("Board") as SortBoard


func _state(runner: GdUnitSceneRunner) -> SortState:
	return _board(runner).get("_state")


func _text(runner: GdUnitSceneRunner, node_name: String) -> String:
	return (runner.find_child(node_name) as Label).text
