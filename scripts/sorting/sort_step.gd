class_name SortStep
extends RefCounted
## One atomic move of a sorting algorithm.
##
## Operands are locations: a non-negative location is an index into the array,
## a negative one is a cache slot (see SortState.cache_location).

enum Type { COMPARE, SWAP, STORE, LOAD, MOVE }

var type: Type
var first: int
var second: int
## What the algorithm is doing at this point, for players following along.
var note := ""


func _init(p_type: Type, p_first: int, p_second: int) -> void:
	type = p_type
	first = p_first
	second = p_second


## What the move asks for, phrased for a hint that highlights its two cells.
func describe() -> String:
	match type:
		Type.SWAP:
			return "swap the two highlighted bars"
		Type.STORE:
			return "store the highlighted bar in the cache"
		Type.LOAD:
			return "load the cached bar into the highlighted gap"
		Type.MOVE:
			return "move the highlighted bar into the highlighted gap"
	return "compare the highlighted bars"


## True when `other` does the same thing; a swap is the same either way round.
func is_same_move(other: SortStep) -> bool:
	if type != other.type:
		return false
	if type == Type.SWAP and first == other.second and second == other.first:
		return true
	return first == other.first and second == other.second


## Look at two elements, wherever they are.
static func compare(first_location: int, second_location: int) -> SortStep:
	return SortStep.new(Type.COMPARE, first_location, second_location)


## Exchange two array elements.
static func swap(first_index: int, second_index: int) -> SortStep:
	return SortStep.new(Type.SWAP, first_index, second_index)


## Move an array element into an empty cache slot, leaving a hole behind.
static func store(index: int, slot: int) -> SortStep:
	return SortStep.new(Type.STORE, index, SortState.cache_location(slot))


## Move a cached element into an empty array position.
static func load_from_cache(slot: int, index: int) -> SortStep:
	return SortStep.new(Type.LOAD, SortState.cache_location(slot), index)


## Move an array element into an empty array position, leaving a hole behind.
static func move(from_index: int, to_index: int) -> SortStep:
	return SortStep.new(Type.MOVE, from_index, to_index)
