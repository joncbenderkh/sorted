class_name Quicksort
extends SortAlgorithm
## Quicksort with the pivot parked in cache slot 0 while partitioning.
##
## Parking the pivot leaves a hole; elements are moved into it from alternating
## ends until the two scans meet, and the pivot is loaded into the last hole.
## Scans stop on equal elements so duplicates split evenly.

const SLOT := 0


func min_cache_size(_item_count: int) -> int:
	return 1


func _run() -> void:
	_sort_range(0, _state.array_size() - 1)


func _sort_range(low: int, high: int) -> void:
	if low >= high:
		return
	var pivot_index := _partition(low, high)
	_sort_range(low, pivot_index - 1)
	_sort_range(pivot_index + 1, high)


func _partition(low: int, high: int) -> int:
	var middle := (low + high) / 2
	_set_phase(
		(
			(
				"Partition positions %d-%d: park a pivot in the cache, move smaller bars left "
				+ "and larger bars right through the gap, then drop the pivot in the gap"
			)
			% [low + 1, high + 1]
		)
	)
	if middle != low:
		_swap(low, middle)
	_store(low, SLOT)
	var pivot := SortState.cache_location(SLOT)
	var left := low
	var right := high
	while left < right:
		while left < right and _less(pivot, right):
			right -= 1
		if left < right:
			_move(right, left)
			left += 1
		while left < right and _less(left, pivot):
			left += 1
		if left < right:
			_move(left, right)
			right -= 1
	_load(SLOT, left)
	return left
