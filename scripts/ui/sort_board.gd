class_name SortBoard
extends Control
## Draws a SortState as bars (the cache on top, the array below) and, when
## interactive, lets the player drag one bar onto another cell.

signal move_requested(source: int, target: int)

const NO_LOCATION := -1000000
const BAR_COLOR := Color("5b8def")
const DONE_COLOR := Color("4caf6a")
const EMPTY_COLOR := Color(1, 1, 1, 0.25)
const DROP_COLOR := Color(1, 1, 1, 0.8)
const DRAG_ALPHA := 0.35
const CACHE_LABEL_WIDTH := 80.0
const CACHE_SLOT_WIDTH := 64.0
const CACHE_SHARE := 0.25
const LABEL_SIZE := 16
const BAR_FILL := 0.8

var max_value := 1
var interactive := false

var _state: SortState
var _highlights: Dictionary = {}
var _done := false
var _drag_source := NO_LOCATION
var _drag_position := Vector2.ZERO


func _ready() -> void:
	resized.connect(queue_redraw)


## `highlights` maps locations to the color they are drawn in.
func show_state(state: SortState, highlights: Dictionary = {}, done: bool = false) -> void:
	_state = state
	_highlights = highlights
	_done = done
	_drag_source = NO_LOCATION
	queue_redraw()


## The slot a location occupies, in this control's coordinates.
func cell_rect(location: int) -> Rect2:
	if SortState.is_cache_location(location):
		var area := _cache_area()
		var count := _state.cache_size()
		var slot_width := minf(CACHE_SLOT_WIDTH, (area.size.x - CACHE_LABEL_WIDTH) / count)
		return Rect2(
			area.position.x + CACHE_LABEL_WIDTH + SortState.cache_slot(location) * slot_width,
			area.position.y,
			slot_width,
			area.size.y
		)
	var array_area := _array_area()
	var width := array_area.size.x / _state.array_size()
	return Rect2(
		array_area.position.x + location * width, array_area.position.y, width, array_area.size.y
	)


## The location under `point`, or NO_LOCATION.
func location_at(point: Vector2) -> int:
	if _state == null:
		return NO_LOCATION
	for slot in _state.cache_size():
		var location := SortState.cache_location(slot)
		if cell_rect(location).has_point(point):
			return location
	for index in _state.array_size():
		if cell_rect(index).has_point(point):
			return index
	return NO_LOCATION


func _gui_input(event: InputEvent) -> void:
	if not interactive or _state == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag(event.position)
	elif event is InputEventMouseMotion and _drag_source != NO_LOCATION:
		_drag_position = event.position
		queue_redraw()


func _begin_drag(point: Vector2) -> void:
	var location := location_at(point)
	if location != NO_LOCATION and not _state.is_empty(location):
		_drag_source = location
		_drag_position = point
		queue_redraw()


func _end_drag(point: Vector2) -> void:
	if _drag_source == NO_LOCATION:
		return
	var source := _drag_source
	var target := location_at(point)
	_drag_source = NO_LOCATION
	queue_redraw()
	if target != NO_LOCATION:
		move_requested.emit(source, target)


func _cache_area() -> Rect2:
	if _state.cache_size() == 0:
		return Rect2()
	return Rect2(0, 0, size.x, size.y * CACHE_SHARE)


func _array_area() -> Rect2:
	var top := _cache_area().size.y
	return Rect2(0, top, size.x, size.y - top)


func _draw() -> void:
	if _state == null:
		return
	if _state.cache_size() > 0:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(8, 24), "Cache", HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE)
	for slot in _state.cache_size():
		_draw_cell(SortState.cache_location(slot))
	for index in _state.array_size():
		_draw_cell(index)
	if _drag_source != NO_LOCATION:
		_draw_drag()


func _draw_cell(location: int) -> void:
	var cell := cell_rect(location)
	var bar_width := maxf(cell.size.x * BAR_FILL, 1.0)
	var left := cell.position.x + (cell.size.x - bar_width) / 2.0
	var value: Variant = _state.get_value(location)
	if value == null:
		draw_rect(Rect2(left, cell.position.y, bar_width, cell.size.y), EMPTY_COLOR, false, 1.0)
		return
	var height := cell.size.y * float(value) / float(max_value)
	var color: Color = _highlights.get(location, DONE_COLOR if _done else BAR_COLOR)
	if location == _drag_source:
		color.a = DRAG_ALPHA
	draw_rect(Rect2(left, cell.end.y - height, bar_width, height), color)


func _draw_drag() -> void:
	var origin := cell_rect(_drag_source)
	var bar_width := maxf(origin.size.x * BAR_FILL, 1.0)
	var height := origin.size.y * float(_state.get_value(_drag_source)) / float(max_value)
	var held := Rect2(
		_drag_position.x - bar_width / 2.0, _drag_position.y - height / 2.0, bar_width, height
	)
	draw_rect(held, BAR_COLOR)
	var target := location_at(_drag_position)
	if target != NO_LOCATION and target != _drag_source:
		draw_rect(cell_rect(target), DROP_COLOR, false, 2.0)
