class_name MergeSort
extends SortAlgorithm
## Top-down merge sort. Merging parks the left half in the cache, then fills
## the holes it leaves with the smaller front element of either run, so the
## cache must hold half the array.


func min_cache_size(item_count: int) -> int:
	return item_count / 2


func _run() -> void:
	_sort_range(0, _state.array_size())


func _sort_range(low: int, high: int) -> void:
	if high - low < 2:
		return
	var middle := (low + high) / 2
	_sort_range(low, middle)
	_sort_range(middle, high)
	_merge(low, middle, high)


func _merge(low: int, middle: int, high: int) -> void:
	var left_count := middle - low
	_set_phase(
		(
			(
				"Merge the sorted runs at positions %d-%d and %d-%d: park the left run in "
				+ "the cache, then refill the array with the smaller front bar of each run"
			)
			% [low + 1, middle, middle + 1, high]
		)
	)
	for slot in left_count:
		_store(low + slot, slot)
	var next_left := 0
	var next_right := middle
	var out := low
	while next_left < left_count and next_right < high:
		if _less(next_right, SortState.cache_location(next_left)):
			_move(next_right, out)
			next_right += 1
		else:
			_load(next_left, out)
			next_left += 1
		out += 1
	while next_left < left_count:
		_load(next_left, out)
		next_left += 1
		out += 1
