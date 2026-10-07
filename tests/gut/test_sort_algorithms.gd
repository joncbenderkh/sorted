extends GutTest

const SEED := 20261007

var _algorithms: Array[GDScript] = [Heapsort, InsertionSort]


func _replay(algorithm: SortAlgorithm, values: Array[int], cache_size: int) -> SortState:
	var steps := algorithm.sort(values, cache_size)
	var state := SortState.new(values, cache_size)
	for step in steps:
		var error := state.apply(step)
		assert_eq(
			error,
			"",
			"illegal step in %s on %s" % [algorithm.get_script().get_global_name(), values]
		)
		if error != "":
			break
	return state


func _assert_sorts(algorithm_class: GDScript, values: Array[int]) -> void:
	var algorithm: SortAlgorithm = algorithm_class.new()
	var cache_size := algorithm.min_cache_size()
	var state := _replay(algorithm, values, cache_size)
	var expected := values.duplicate()
	expected.sort()
	var actual: Array = []
	for i in state.array_size():
		actual.append(state.get_value(i))
	assert_eq(actual, expected, "%s on %s" % [algorithm_class.get_global_name(), values])
	assert_true(state.is_sorted())


func test_edge_cases() -> void:
	for algorithm_class in _algorithms:
		_assert_sorts(algorithm_class, [])
		_assert_sorts(algorithm_class, [1])
		_assert_sorts(algorithm_class, [2, 1])
		_assert_sorts(algorithm_class, [1, 2, 3, 4, 5])
		_assert_sorts(algorithm_class, [5, 4, 3, 2, 1])
		_assert_sorts(algorithm_class, [3, 3, 3, 3])
		_assert_sorts(algorithm_class, [2, 1, 2, 1, 2, 1])


func test_random_arrays() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for algorithm_class in _algorithms:
		for size in range(0, 40):
			var values: Array[int] = []
			for i in size:
				values.append(rng.randi_range(0, 20))
			_assert_sorts(algorithm_class, values)


func test_larger_cache_is_accepted() -> void:
	var algorithm := InsertionSort.new()
	var values: Array[int] = [4, 2, 3, 1]
	var state := _replay(algorithm, values, 3)
	assert_true(state.is_sorted())


func test_cache_below_minimum_is_rejected() -> void:
	var algorithm := InsertionSort.new()
	var values: Array[int] = [2, 1]
	var steps := algorithm.sort(values, 0)
	assert_eq(steps.size(), 0)
	assert_push_error("needs a cache of at least 1 slots")


func test_heapsort_never_touches_cache() -> void:
	var values: Array[int] = [5, 3, 8, 1, 9, 2, 7]
	for step in Heapsort.new().sort(values, 0):
		assert_true(step.type in [SortStep.Type.COMPARE, SortStep.Type.SWAP])
		assert_false(SortState.is_cache_location(step.first))
		assert_false(SortState.is_cache_location(step.second))
