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

# Medium heights, by letter (from 0): swaying letters (1, 4, 7) need a hop in levels 1-20 and a held jump
# from level 21; the other odd letters always need a held jump; the rest are walked through.
func test_medium_balloon_heights_in_the_first_twenty_levels() -> void:
	assert_array(_medium_heights(0)).is_equal([85.0, 170.0, 85.0, 250.0, 170.0, 250.0, 85.0, 170.0, 85.0, 250.0])
	assert_array(_medium_heights(19)).is_equal(_medium_heights(0))

func test_medium_balloon_heights_from_level_twenty_one() -> void:
	assert_array(_medium_heights(20)).is_equal([85.0, 250.0, 85.0, 250.0, 250.0, 250.0, 85.0, 250.0, 85.0, 250.0])
	assert_array(_medium_heights(39)).is_equal(_medium_heights(20))

func test_easy_balloons_are_all_walked_through() -> void:
	var heights: Array = range(10).map(func(i): return HillsLevelScript.balloon_height(i, 39, HillsLevels.EASY))
	assert_array(heights.filter(func(h): return h != 85.0)).is_empty()

# A high balloon never sits on top of a pot: one that would stays low instead
func test_no_high_balloon_crowds_a_pot() -> void:
	var bad := []
	for level_index in Levels.level_count():
		var level := await open_level(level_index, HillsLevels.MEDIUM)
		for balloon in _balloons(level):
			for pot in find_pots(level):
				if absf(balloon.anchor.x - pot.position.x) < balloon.sway_distance + HillsLevelScript.BALLOON_CLEAR_OF_POT and balloon.anchor.y < pot.position.y:
					bad.append("%d %s: %s over the %s pot" % [level_index + 1, level.level.name, balloon.letter, pot.paint_name])
	assert_array(bad).is_empty()

func _medium_heights(level_index: int) -> Array:
	return range(10).map(func(i): return HillsLevelScript.balloon_height(i, level_index, HillsLevels.MEDIUM))
