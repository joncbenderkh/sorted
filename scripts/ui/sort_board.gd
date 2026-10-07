class_name SortBoard
extends Control
## Draws a SortState as bars: the cache on top, the array below.

const BAR_COLOR := Color("5b8def")
const DONE_COLOR := Color("4caf6a")
const EMPTY_COLOR := Color(1, 1, 1, 0.25)
const CACHE_LABEL_WIDTH := 80.0
const CACHE_SLOT_WIDTH := 64.0
const CACHE_SHARE := 0.25
const LABEL_SIZE := 16
const BAR_FILL := 0.8

var max_value := 1

var _state: SortState
var _highlights: Dictionary = {}
var _done := false


func _ready() -> void:
	resized.connect(queue_redraw)


## `highlights` maps locations to the color they are drawn in.
func show_state(state: SortState, highlights: Dictionary = {}, done: bool = false) -> void:
	_state = state
	_highlights = highlights
	_done = done
	queue_redraw()


func _draw() -> void:
	if _state == null:
		return
	var cache_height := 0.0
	if _state.cache_size() > 0:
		cache_height = size.y * CACHE_SHARE
		_draw_cache(Rect2(0, 0, size.x, cache_height))
	_draw_array(Rect2(0, cache_height, size.x, size.y - cache_height))


func _draw_cache(area: Rect2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, 24), "Cache", HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE)
	var count := _state.cache_size()
	var slot_width := minf(CACHE_SLOT_WIDTH, (area.size.x - CACHE_LABEL_WIDTH) / count)
	for slot in count:
		var cell := Rect2(
			area.position.x + CACHE_LABEL_WIDTH + slot * slot_width,
			area.position.y,
			slot_width,
			area.size.y
		)
		_draw_cell(SortState.cache_location(slot), cell)


func _draw_array(area: Rect2) -> void:
	var count := _state.array_size()
	if count == 0:
		return
	var slot_width := area.size.x / count
	for index in count:
		var cell := Rect2(
			area.position.x + index * slot_width, area.position.y, slot_width, area.size.y
		)
		_draw_cell(index, cell)


func _draw_cell(location: int, cell: Rect2) -> void:
	var bar_width := maxf(cell.size.x * BAR_FILL, 1.0)
	var left := cell.position.x + (cell.size.x - bar_width) / 2.0
	var value: Variant = _state.get_value(location)
	if value == null:
		var outline := Rect2(left, cell.position.y, bar_width, cell.size.y)
		draw_rect(outline, EMPTY_COLOR, false, 1.0)
		return
	var height := cell.size.y * float(value) / float(max_value)
	var color: Color = _highlights.get(location, DONE_COLOR if _done else BAR_COLOR)
	draw_rect(Rect2(left, cell.end.y - height, bar_width, height), color)
