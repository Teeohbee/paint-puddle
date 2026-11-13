extends HillsSuite
# Letter balloons: on Medium every third one sways, from the second letter, so the first is always a
# still one to learn on. Easy balloons never sway.

func test_on_medium_every_third_balloon_sways_from_the_second() -> void:
	var level := await open_level(0, HillsLevels.MEDIUM)
	var swaying: Array = _balloons(level).filter(func(b): return b.sway_distance > 0.0).map(func(b): return b.letter_index)
	var word := Levels.word_for(level.level, "medium")
	var expected: Array = range(word.length()).filter(func(i): return i % 3 == 1)
	assert_int(word.length()).is_greater_equal(5)
	assert_array(swaying).override_failure_message("in %s, the balloons for letters %s sway, wanted %s" % [word, swaying, expected]).is_equal(expected)

func test_on_easy_no_balloon_sways() -> void:
	var level := await open_level(0)
	assert_array(_balloons(level).filter(func(b): return b.sway_distance > 0.0)).is_empty()

func _balloons(level: Node) -> Array:
	var balloons: Array = level.effects_layer.get_children().filter(func(c): return _is_script(c, "res://hills/letter_balloon.gd"))
	balloons.sort_custom(func(a, b): return a.letter_index < b.letter_index)
	return balloons
