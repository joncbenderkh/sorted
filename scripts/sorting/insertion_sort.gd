class_name InsertionSort
extends SortAlgorithm
## Insertion sort holding the element being placed in cache slot 0.

const SLOT := 0


func min_cache_size() -> int:
	return 1


func _run() -> void:
	var held := SortState.cache_location(SLOT)
	for i in range(1, _state.array_size()):
		_store(i, SLOT)
		var hole := i
		while hole > 0 and _less(held, hole - 1):
			_move(hole - 1, hole)
			hole -= 1
		_load(SLOT, hole)
