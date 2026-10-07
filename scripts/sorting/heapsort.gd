class_name Heapsort
extends SortAlgorithm
## In-place heapsort; needs no cache.


func _run() -> void:
	var count := _state.array_size()
	for start in range(count / 2 - 1, -1, -1):
		_set_phase(
			(
				"Build a max-heap: sift the bar at position %d down until both its children are smaller"
				% (start + 1)
			)
		)
		_sift_down(start, count)
	for end in range(count - 1, 0, -1):
		_set_phase(
			(
				"Swap the largest remaining bar to position %d, then sift the new top down to repair the heap"
				% (end + 1)
			)
		)
		_swap(0, end)
		_sift_down(0, end)


func _sift_down(root: int, end: int) -> void:
	while true:
		var child := 2 * root + 1
		if child >= end:
			return
		if child + 1 < end and _less(child, child + 1):
			child += 1
		if not _less(root, child):
			return
		_swap(root, child)
		root = child
