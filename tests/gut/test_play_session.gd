extends GutTest

const SEED := 20261008

var _algorithms: Array[GDScript] = [Heapsort, InsertionSort, MergeSort, Quicksort]


func _shuffled(count: int, rng: RandomNumberGenerator) -> Array[int]:
	var values: Array[int] = []
	for i in count:
		values.append(i + 1)
	while true:
		for i in range(count - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var held := values[i]
			values[i] = values[j]
			values[j] = held
		if not SortState.new(values).is_sorted():
			return values
	return values


func _session(algorithm_class: GDScript, mode: PlaySession.Mode, count: int = 12) -> PlaySession:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var algorithm: SortAlgorithm = algorithm_class.new()
	var values := _shuffled(count, rng)
	return PlaySession.new(values, algorithm, mode, algorithm.min_cache_size(count))


func _algorithm_moves(algorithm_class: GDScript, count: int = 12) -> Array[SortStep]:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var algorithm: SortAlgorithm = algorithm_class.new()
	var values := _shuffled(count, rng)
	var moves: Array[SortStep] = []
	for step in algorithm.sort(values, algorithm.min_cache_size(count)):
		if step.type != SortStep.Type.COMPARE:
			moves.append(step)
	return moves


func test_replaying_the_algorithm_finishes_at_or_under_par_in_both_modes() -> void:
	for algorithm_class in _algorithms:
		for mode in [PlaySession.Mode.FREE, PlaySession.Mode.GUIDED]:
			var session := _session(algorithm_class, mode)
			var name := "%s %s" % [algorithm_class.get_global_name(), mode]
			assert_false(session.is_finished(), name)
			for step in _algorithm_moves(algorithm_class):
				if session.is_finished():
					break
				assert_eq(session.try_move(step), "", name)
			assert_true(session.is_finished(), name)
			assert_lte(session.moves_used, session.par, name)
			assert_true(session.state.is_sorted(), name)


func test_par_is_the_algorithms_move_count() -> void:
	for algorithm_class in _algorithms:
		var session := _session(algorithm_class, PlaySession.Mode.FREE)
		assert_eq(session.par, _algorithm_moves(algorithm_class).size())


func test_free_play_accepts_and_counts_any_legal_move() -> void:
	var session := _session(Heapsort, PlaySession.Mode.FREE)
	var before: Variant = session.state.get_value(0)
	assert_eq(session.try_move(SortStep.swap(0, 1)), "")
	assert_eq(session.moves_used, 1)
	assert_ne(session.state.get_value(0), before)
	assert_null(session.expected_step())


func test_illegal_moves_are_refused_with_the_states_reason_and_not_counted() -> void:
	var session := _session(InsertionSort, PlaySession.Mode.FREE)
	assert_string_contains(session.try_move(SortStep.move(0, 1)), "occupied")
	assert_eq(session.moves_used, 0)
	assert_eq(session.try_move(SortStep.store(0, 0)), "")
	assert_string_contains(session.try_move(SortStep.store(1, 0)), "occupied")
	assert_eq(session.moves_used, 1)


func test_guided_rejects_a_legal_but_wrong_move_and_changes_nothing() -> void:
	var session := _session(InsertionSort, PlaySession.Mode.GUIDED)
	var before := [session.state.get_value(0), session.state.get_value(1)]
	assert_eq(session.try_move(SortStep.swap(0, 1)), "not the algorithm's next move")
	assert_eq(session.moves_used, 0)
	assert_eq([session.state.get_value(0), session.state.get_value(1)], before)


func test_guided_exposes_and_advances_the_expected_move() -> void:
	var session := _session(InsertionSort, PlaySession.Mode.GUIDED)
	var moves := _algorithm_moves(InsertionSort)
	for i in 3:
		assert_true(session.expected_step().is_same_move(moves[i]))
		assert_eq(session.try_move(moves[i]), "")


func test_guided_accepts_a_swap_with_its_operands_reversed() -> void:
	var session := _session(Heapsort, PlaySession.Mode.GUIDED)
	var first := session.expected_step()
	assert_eq(first.type, SortStep.Type.SWAP)
	assert_eq(session.try_move(SortStep.swap(first.second, first.first)), "")


func test_no_moves_are_accepted_once_sorted() -> void:
	var session := _session(Quicksort, PlaySession.Mode.FREE)
	for step in _algorithm_moves(Quicksort):
		session.try_move(step)
	var used := session.moves_used
	assert_eq(session.try_move(SortStep.swap(0, 1)), "already sorted")
	assert_eq(session.moves_used, used)


func test_result_text_reports_moves_and_par() -> void:
	var session := _session(Heapsort, PlaySession.Mode.FREE)
	session.try_move(SortStep.swap(0, 1))
	assert_eq(session.result_text(), "Sorted in 1 moves (par %d)" % session.par)


func test_step_equality_ignores_swap_operand_order_only() -> void:
	assert_true(SortStep.swap(1, 2).is_same_move(SortStep.swap(2, 1)))
	assert_false(SortStep.move(1, 2).is_same_move(SortStep.move(2, 1)))
	assert_false(SortStep.swap(1, 2).is_same_move(SortStep.move(1, 2)))
