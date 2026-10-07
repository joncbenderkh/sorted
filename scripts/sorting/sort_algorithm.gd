class_name SortAlgorithm
extends RefCounted
## Base class for sorting algorithms.
##
## An algorithm is pure logic: it runs against a SortState and records every
## move as a SortStep. Rendering and the game layer replay those steps.
## Subclasses implement _run() using the _compare/_swap/_store/_load/_move
## helpers.

var _state: SortState
var _steps: Array[SortStep] = []
var _phase := ""


## The smallest cache the algorithm can run with on `item_count` elements.
func min_cache_size(_item_count: int) -> int:
	return 0


## Returns the steps that sort `values` using a cache of `cache_size` slots.
func sort(values: Array[int], cache_size: int) -> Array[SortStep]:
	_steps = []
	_phase = ""
	var needed := min_cache_size(values.size())
	if cache_size < needed:
		push_error("needs a cache of at least %d slots" % needed)
		return _steps
	_state = SortState.new(values, cache_size)
	_run()
	return _steps


## Describes what the following steps are for; every recorded step carries it.
func _set_phase(description: String) -> void:
	_phase = description


func _run() -> void:
	push_error("_run() must be overridden")


## True when the element at `first` is smaller than the one at `second`.
func _less(first: int, second: int) -> bool:
	_record(SortStep.compare(first, second))
	return _state.get_value(first) < _state.get_value(second)


func _swap(first: int, second: int) -> void:
	_record(SortStep.swap(first, second))


func _store(index: int, slot: int) -> void:
	_record(SortStep.store(index, slot))


func _load(slot: int, index: int) -> void:
	_record(SortStep.load_from_cache(slot, index))


func _move(from_index: int, to_index: int) -> void:
	_record(SortStep.move(from_index, to_index))


func _record(step: SortStep) -> void:
	step.note = _phase
	var error := _state.apply(step)
	if error != "":
		push_error("illegal step: %s" % error)
	_steps.append(step)
