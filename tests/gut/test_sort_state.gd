extends GutTest


func _state(values: Array[int], cache_size: int = 1) -> SortState:
	return SortState.new(values, cache_size)


func test_swap_exchanges_elements() -> void:
	var state := _state([3, 1, 2])
	assert_eq(state.apply(SortStep.swap(0, 2)), "")
	assert_eq([state.get_value(0), state.get_value(1), state.get_value(2)], [2, 1, 3])


func test_store_leaves_hole_and_load_fills_it() -> void:
	var state := _state([3, 1, 2])
	assert_eq(state.apply(SortStep.store(0, 0)), "")
	assert_true(state.is_empty(0))
	assert_eq(state.get_value(SortState.cache_location(0)), 3)
	assert_eq(state.apply(SortStep.load_from_cache(0, 0)), "")
	assert_eq(state.get_value(0), 3)
	assert_true(state.is_empty(SortState.cache_location(0)))


func test_move_requires_empty_destination() -> void:
	var state := _state([3, 1, 2])
	assert_ne(state.apply(SortStep.move(0, 1)), "")
	state.apply(SortStep.store(1, 0))
	assert_eq(state.apply(SortStep.move(0, 1)), "")
	assert_eq(state.get_value(1), 3)


func test_cache_cannot_exceed_its_size() -> void:
	var state := _state([3, 1, 2], 1)
	state.apply(SortStep.store(0, 0))
	assert_ne(state.apply(SortStep.store(1, 0)), "")
	assert_ne(state.apply(SortStep.store(1, 1)), "")


func test_empty_cells_cannot_be_read() -> void:
	var state := _state([3, 1, 2])
	state.apply(SortStep.store(0, 0))
	assert_ne(state.apply(SortStep.compare(0, 1)), "")
	assert_ne(state.apply(SortStep.swap(0, 1)), "")
	assert_ne(state.apply(SortStep.move(0, 1)), "")


func test_out_of_range_locations_are_rejected() -> void:
	var state := _state([3, 1, 2])
	assert_ne(state.apply(SortStep.compare(0, 3)), "")
	assert_ne(state.apply(SortStep.compare(0, SortState.cache_location(1))), "")


func test_failed_step_leaves_state_unchanged() -> void:
	var state := _state([3, 1, 2])
	state.apply(SortStep.move(0, 1))
	assert_eq([state.get_value(0), state.get_value(1), state.get_value(2)], [3, 1, 2])


func test_swap_rejects_cache_operands() -> void:
	var state := _state([3, 1, 2])
	assert_ne(state.apply(SortStep.swap(0, SortState.cache_location(0))), "")


func test_is_sorted_needs_ordered_array_and_empty_cache() -> void:
	assert_true(_state([1, 2, 3]).is_sorted())
	assert_false(_state([2, 1, 3]).is_sorted())
	var state := _state([1, 2, 3])
	state.apply(SortStep.store(2, 0))
	assert_false(state.is_sorted())
