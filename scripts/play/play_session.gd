class_name PlaySession
extends RefCounted
## A human sorting the array, one move at a time.
##
## In FREE mode any legal move is accepted. In GUIDED mode only the next move
## of the chosen algorithm is. Compares are not player moves (values are
## visible), so par is the algorithm's step count without them.

enum Mode { FREE, GUIDED }

var state: SortState
var mode: Mode
var moves_used := 0
var par := 0

var _moves: Array[SortStep] = []
var _next := 0


func _init(values: Array[int], algorithm: SortAlgorithm, p_mode: Mode, cache_size: int) -> void:
	state = SortState.new(values, cache_size)
	mode = p_mode
	for step in algorithm.sort(values, cache_size):
		if step.type != SortStep.Type.COMPARE:
			_moves.append(step)
	par = _moves.size()


## The move the algorithm makes next; null in free play or once it is done.
func expected_step() -> SortStep:
	if mode == Mode.GUIDED and _next < _moves.size():
		return _moves[_next]
	return null


## Sorted is sorted: an algorithm can spend its last moves on an array that is
## already in order, so finishing under par is possible in both modes.
func is_finished() -> bool:
	return state.is_sorted()


## Applies the player's move. Returns an empty string, or why it was refused
## (in which case nothing changed and the move is not counted).
func try_move(step: SortStep) -> String:
	var error := ""
	var expected := expected_step()
	if is_finished():
		error = "already sorted"
	elif mode == Mode.GUIDED and (expected == null or not expected.is_same_move(step)):
		error = "not the algorithm's next move"
	else:
		error = state.apply(step)
	if error == "":
		moves_used += 1
		_next += 1
	return error


func result_text() -> String:
	return "Sorted in %d moves (par %d)" % [moves_used, par]
