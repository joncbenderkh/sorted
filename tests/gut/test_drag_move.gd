extends GutTest

var _cache0 := SortState.cache_location(0)
var _cache1 := SortState.cache_location(1)


func _state(cache_size: int = 2) -> SortState:
	var values: Array[int] = [3, 1, 2]
	return SortState.new(values, cache_size)


func _assert_step(step: SortStep, type: SortStep.Type, first: int, second: int) -> void:
	assert_not_null(step)
	assert_eq(step.type, type)
	assert_eq(step.first, first)
	assert_eq(step.second, second)


func test_filled_to_filled_array_cell_is_a_swap() -> void:
	_assert_step(DragMove.to_step(_state(), 0, 2), SortStep.Type.SWAP, 0, 2)


func test_filled_to_empty_array_cell_is_a_move() -> void:
	var state := _state()
	state.apply(SortStep.store(1, 0))
	_assert_step(DragMove.to_step(state, 0, 1), SortStep.Type.MOVE, 0, 1)


func test_array_to_cache_slot_is_a_store() -> void:
	_assert_step(DragMove.to_step(_state(), 2, _cache1), SortStep.Type.STORE, 2, _cache1)


func test_cache_to_array_cell_is_a_load() -> void:
	var state := _state()
	state.apply(SortStep.store(0, 0))
	_assert_step(DragMove.to_step(state, _cache0, 0), SortStep.Type.LOAD, _cache0, 0)


func test_drags_that_ask_for_nothing_return_null() -> void:
	var state := _state()
	state.apply(SortStep.store(0, 0))
	assert_null(DragMove.to_step(state, 1, 1), "same cell")
	assert_null(DragMove.to_step(state, 0, 1), "empty source")
	assert_null(DragMove.to_step(state, _cache1, 1), "empty cache source")
	state.apply(SortStep.store(1, 1))
	assert_null(DragMove.to_step(state, _cache0, _cache1), "cache to cache")
	assert_null(DragMove.to_step(state, 2, 7), "unknown target")
	assert_null(DragMove.to_step(state, -9, 2), "unknown source")


func test_legality_is_left_to_the_state() -> void:
	var state := _state(1)
	state.apply(SortStep.store(0, 0))
	var step := DragMove.to_step(state, 1, _cache0)
	assert_not_null(step)
	assert_ne(state.apply(step), "", "cache slot is occupied")
