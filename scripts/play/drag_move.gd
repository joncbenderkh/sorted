class_name DragMove
extends RefCounted
## Turns a drag from one cell to another into the SortStep it asks for.
##
## Only the intent is decided here; whether the step is legal is up to
## SortState.apply.


## Returns null when the drag asks for nothing: same cell, an empty source, an
## unknown cell, or a cache-to-cache move.
static func to_step(state: SortState, source: int, target: int) -> SortStep:
	var step: SortStep = null
	var usable := (
		source != target
		and state.is_valid_location(source)
		and state.is_valid_location(target)
		and not state.is_empty(source)
	)
	if usable:
		var from_cache := SortState.is_cache_location(source)
		var to_cache := SortState.is_cache_location(target)
		if from_cache and not to_cache:
			step = SortStep.load_from_cache(SortState.cache_slot(source), target)
		elif to_cache and not from_cache:
			step = SortStep.store(source, SortState.cache_slot(target))
		elif not from_cache and not to_cache:
			step = (
				SortStep.move(source, target)
				if state.is_empty(target)
				else SortStep.swap(source, target)
			)
	return step
