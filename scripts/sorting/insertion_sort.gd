class_name InsertionSort
extends SortAlgorithm
## Insertion sort holding the element being placed in cache slot 0.

const SLOT := 0


func min_cache_size(_item_count: int) -> int:
	return 1


func _run() -> void:
	var held := SortState.cache_location(SLOT)
	for i in range(1, _state.array_size()):
		_set_phase(
			(
				(
					"Insert the bar at position %d into the sorted bars on its left: "
					+ "lift it into the cache, shift larger bars right, drop it in the gap"
				)
				% (i + 1)
			)
		)
		_store(i, SLOT)
		var hole := i
		while hole > 0 and _less(held, hole - 1):
			_move(hole - 1, hole)
			hole -= 1
		_load(SLOT, hole)
