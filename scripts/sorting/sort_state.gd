class_name SortState
extends RefCounted
## The array and cache an algorithm works on.
##
## Every step is validated against the state, so an algorithm (or a human
## player replacing it) cannot cheat: no overwriting elements, no exceeding the
## cache size, no reading empty cells.

var _array: Array = []
var _cache: Array = []


func _init(values: Array[int], cache_size: int = 0) -> void:
	_array.assign(values)
	_cache.resize(cache_size)


static func cache_location(slot: int) -> int:
	return -(slot + 1)


static func is_cache_location(location: int) -> bool:
	return location < 0


static func cache_slot(location: int) -> int:
	return -location - 1


func array_size() -> int:
	return _array.size()


func cache_size() -> int:
	return _cache.size()


func is_valid_location(location: int) -> bool:
	if is_cache_location(location):
		return -location <= _cache.size()
	return location < _array.size()


## The element at a location, or null for an empty cell.
func get_value(location: int) -> Variant:
	if is_cache_location(location):
		return _cache[-location - 1]
	return _array[location]


func is_empty(location: int) -> bool:
	return get_value(location) == null


## True when every element is back in the array, in ascending order.
func is_sorted() -> bool:
	for slot in _cache:
		if slot != null:
			return false
	for i in _array.size():
		if _array[i] == null or (i > 0 and _array[i - 1] > _array[i]):
			return false
	return true


## Applies a step and returns an empty string, or the reason it is illegal
## (in which case the state is left unchanged).
func apply(step: SortStep) -> String:
	var error := _validate(step)
	if error != "":
		return error
	match step.type:
		SortStep.Type.SWAP:
			var held = get_value(step.first)
			_set_value(step.first, get_value(step.second))
			_set_value(step.second, held)
		SortStep.Type.STORE, SortStep.Type.LOAD, SortStep.Type.MOVE:
			_set_value(step.second, get_value(step.first))
			_set_value(step.first, null)
	return ""


func _validate(step: SortStep) -> String:
	for location in [step.first, step.second]:
		if not is_valid_location(location):
			return "location %d is out of range" % location
	var first_cache := is_cache_location(step.first)
	var second_cache := is_cache_location(step.second)
	var error := ""
	match step.type:
		SortStep.Type.COMPARE:
			error = _require_filled([step.first, step.second])
		SortStep.Type.SWAP:
			error = "swap works on array elements only"
			if not first_cache and not second_cache:
				error = _require_filled([step.first, step.second])
		SortStep.Type.STORE:
			error = "store moves an array element into the cache"
			if not first_cache and second_cache:
				error = _require_transfer(step)
		SortStep.Type.LOAD:
			error = "load moves a cached element into the array"
			if first_cache and not second_cache:
				error = _require_transfer(step)
		SortStep.Type.MOVE:
			error = "move works on array elements only"
			if not first_cache and not second_cache:
				error = _require_transfer(step)
	return error


func _require_filled(locations: Array) -> String:
	for location in locations:
		if is_empty(location):
			return "location %d is empty" % location
	return ""


func _require_transfer(step: SortStep) -> String:
	if is_empty(step.first):
		return "location %d is empty" % step.first
	if not is_empty(step.second):
		return "location %d is occupied" % step.second
	return ""


func _set_value(location: int, value: Variant) -> void:
	if is_cache_location(location):
		_cache[-location - 1] = value
	else:
		_array[location] = value
