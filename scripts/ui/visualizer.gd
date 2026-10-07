extends Control
## Plays a sorting algorithm's steps on a SortBoard, or lets the player make
## the moves (free play against par, or guided along the algorithm).

enum Mode { WATCH, FREE, GUIDED }

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
const HINT_COLOR := Color("4cc9f0")
const ERROR_COLOR := Color("ff6b6b")
const MESSAGE_SECONDS := 3.0
const MODE_NAMES: Array[String] = ["Watch", "Free play", "Guided"]

var _algorithms: Dictionary = {
	"Heapsort": Heapsort,
	"Insertion sort": InsertionSort,
	"Merge sort": MergeSort,
	"Quicksort": Quicksort
}
var _state: SortState
var _session: PlaySession
var _steps: Array[SortStep] = []
var _step_index := 0
var _playing := false
var _accumulator := 0.0
var _board: SortBoard
var _mode_picker: OptionButton
var _algorithm_picker: OptionButton
var _items_slider: HSlider
var _speed_slider: HSlider
var _play_button: Button
var _step_button: Button
var _hint_button: Button
var _status: Label
var _message: Label
var _message_timer: Timer


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

	_mode_picker = OptionButton.new()
	_mode_picker.name = "ModePicker"
	_mode_picker.custom_minimum_size.y = CONTROL_HEIGHT
	for mode_name in MODE_NAMES:
		_mode_picker.add_item(mode_name)
	_mode_picker.item_selected.connect(func(_index: int) -> void: _reset())
	toolbar.add_child(_mode_picker)

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
	_hint_button = _add_button(toolbar, "Hint", _show_hint)

	_status = Label.new()
	_status.name = "Status"
	toolbar.add_child(_status)

	_message = Label.new()
	_message.name = "Message"
	_message.add_theme_color_override("font_color", ERROR_COLOR)
	root.add_child(_message)

	_message_timer = Timer.new()
	_message_timer.one_shot = true
	_message_timer.timeout.connect(func() -> void: _message.text = "")
	add_child(_message_timer)

	_board = SortBoard.new()
	_board.name = "Board"
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.move_requested.connect(_on_move_requested)
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
	while SortState.new(values).is_sorted():
		values.shuffle()
	var algorithm_name := _algorithm_picker.get_item_text(_algorithm_picker.selected)
	var algorithm: SortAlgorithm = _algorithms[algorithm_name].new()
	var cache_size := algorithm.min_cache_size(count)
	_session = null
	_steps = []
	if _mode_picker.selected == Mode.WATCH:
		_steps = algorithm.sort(values, cache_size)
		_state = SortState.new(values, cache_size)
	else:
		var play_mode := (
			PlaySession.Mode.FREE if _mode_picker.selected == Mode.FREE else PlaySession.Mode.GUIDED
		)
		_session = PlaySession.new(values, algorithm, play_mode, cache_size)
		_state = _session.state
	_step_index = 0
	_message.text = ""
	_play_button.disabled = _session != null
	_speed_slider.editable = _session == null
	_hint_button.visible = _mode_picker.selected == Mode.GUIDED
	_set_playing(false)
	_board.interactive = _session != null
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
	_step_button.disabled = playing or _session != null


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


func _on_move_requested(source: int, target: int) -> void:
	if _session == null:
		return
	var step := DragMove.to_step(_state, source, target)
	if step == null:
		return
	var error := _session.try_move(step)
	if error != "":
		_show_message(error)
		_board.show_state(_state)
		return
	_message.text = ""
	var done := _session.is_finished()
	_board.show_state(_state, {} if done else _highlights_for(step), done)
	_update_status()


func _show_hint() -> void:
	var step := _session.expected_step() if _session != null else null
	if step != null:
		_board.show_state(_state, {step.first: HINT_COLOR, step.second: HINT_COLOR})


func _show_message(text: String) -> void:
	_message.text = text
	_message_timer.start(MESSAGE_SECONDS)


func _update_status() -> void:
	if _session == null:
		_status.text = "step %d / %d" % [_step_index, _steps.size()]
	elif _session.is_finished():
		_status.text = _session.result_text()
	else:
		_status.text = "moves %d / par %d" % [_session.moves_used, _session.par]
