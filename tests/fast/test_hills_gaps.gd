extends HillsSuite
# Medium's gaps are a quarter wider than Easy's. Leap (level 3) opens with a gap of 120.

func test_on_easy_gaps_are_as_written() -> void:
	var level := await open_level(2)
	assert_float(_first_gap(level)).is_equal_approx(120.0, 0.001)

func test_on_medium_gaps_are_a_quarter_wider() -> void:
	var level := await open_level(2, HillsLevels.MEDIUM)
	assert_float(_first_gap(level)).is_equal_approx(150.0, 0.001)

func _first_gap(level: Node) -> float:
	var tops: Array = level.ground.ground_tops
	return tops[1][0].x - tops[0][tops[0].size() - 1].x
