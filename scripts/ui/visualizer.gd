extends Control
## Plays a sorting algorithm's steps on a SortBoard.

const MIN_ITEMS := 8
const MAX_ITEMS := 128
const DEFAULT_ITEMS := 32
const MIN_SPEED := 1.0
const MAX_SPEED := 500.0
const DEFAULT_SPEED := 30.0
const CONTROL_HEIGHT := 48.0
const COMPARE_COLOR := Color("f2c14e")
const SWAP_COLOR := Color("e5484d")
const MOVE_COLOR := Color("b57bee")

var _algorithms: Dictionary = {
	"Heapsort": Heapsort,
	"Insertion sort": InsertionSort,
	"Merge sort": MergeSort,
	"Quicksort": Quicksort
}
var _state: SortState
var _steps: Array[SortStep] = []
var _step_index := 0
var _playing := false
var _accumulator := 0.0
var _board: SortBoard
var _algorithm_picker: OptionButton
var _items_slider: HSlider
var _speed_slider: HSlider
var _play_button: Button
var _step_button: Button
var _status: Label


func _ready() -> void:
	_build_ui()
	_reset()


func _process(delta: float) -> void:
	if not _playing:
		return
	_accumulator += delta
	var interval := 1.0 / _speed_slider.value
	while _accumulator >= interval and _playing:
		_accumulator -= interval
		if not _advance():
			_set_playing(false)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var toolbar := HFlowContainer.new()
	root.add_child(toolbar)

	var title := Label.new()
	title.text = "Sorted %s" % Version.CURRENT
	toolbar.add_child(title)

	_algorithm_picker = OptionButton.new()
	_algorithm_picker.name = "AlgorithmPicker"
	_algorithm_picker.custom_minimum_size.y = CONTROL_HEIGHT
	for algorithm_name in _algorithms:
		_algorithm_picker.add_item(algorithm_name)
	_algorithm_picker.item_selected.connect(func(_index: int) -> void: _reset())
	toolbar.add_child(_algorithm_picker)

	_items_slider = _add_slider(toolbar, "Items", MIN_ITEMS, MAX_ITEMS, DEFAULT_ITEMS)
	_items_slider.value_changed.connect(func(_value: float) -> void: _reset())
	_speed_slider = _add_slider(toolbar, "Steps/s", MIN_SPEED, MAX_SPEED, DEFAULT_SPEED)

	_add_button(toolbar, "Shuffle", _reset)
	_play_button = _add_button(toolbar, "Play", _toggle_playing)
	_step_button = _add_button(toolbar, "Step", _step_once)

	_status = Label.new()
	toolbar.add_child(_status)

	_board = SortBoard.new()
	_board.name = "Board"
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_board)


func _add_slider(
	parent: Control, label_text: String, min_value: float, max_value: float, initial: float
) -> HSlider:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1.0
	slider.value = initial
	slider.custom_minimum_size = Vector2(160, CONTROL_HEIGHT)
	parent.add_child(slider)
	return slider


func _add_button(parent: Control, label: String, handler: Callable) -> Button:
	var button := Button.new()
	button.name = label + "Button"
	button.text = label
	button.custom_minimum_size.y = CONTROL_HEIGHT
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _reset() -> void:
	var count := int(_items_slider.value)
	var values: Array[int] = []
	for i in count:
		values.append(i + 1)
	values.shuffle()
	var algorithm_name := _algorithm_picker.get_item_text(_algorithm_picker.selected)
	var algorithm: SortAlgorithm = _algorithms[algorithm_name].new()
	var cache_size := algorithm.min_cache_size(count)
	_steps = algorithm.sort(values, cache_size)
	_state = SortState.new(values, cache_size)
	_step_index = 0
	_set_playing(false)
	_board.max_value = count
	_board.show_state(_state)
	_update_status()


func _toggle_playing() -> void:
	if _step_index >= _steps.size():
		_reset()
	_set_playing(not _playing)


func _set_playing(playing: bool) -> void:
	_playing = playing
	_accumulator = 0.0
	_play_button.text = "Pause" if playing else "Play"
	_step_button.disabled = playing


func _step_once() -> void:
	_advance()


func _advance() -> bool:
	if _step_index >= _steps.size():
		return false
	var step := _steps[_step_index]
	var error := _state.apply(step)
	if error != "":
		push_error("illegal step: %s" % error)
	_step_index += 1
	var finished := _step_index == _steps.size()
	var done := finished and _state.is_sorted()
	_board.show_state(_state, {} if done else _highlights_for(step), done)
	_update_status()
	return not finished


func _highlights_for(step: SortStep) -> Dictionary:
	var color := MOVE_COLOR
	match step.type:
		SortStep.Type.COMPARE:
			color = COMPARE_COLOR
		SortStep.Type.SWAP:
			color = SWAP_COLOR
	return {step.first: color, step.second: color}


func _update_status() -> void:
	_status.text = "step %d / %d" % [_step_index, _steps.size()]
