extends GdUnitTestSuite
# The rules every Rainbow Hills level keeps, read straight from the level data: a blob can always make the
# jumps, every pot changes its paint, every scene draws.

const Levels = preload("res://hills/hills_levels.gd")
const HillsLevelScript = preload("res://hills/hills_level.gd")
const Scenes = preload("res://hills/hills_scenes.gd")

func test_there_are_forty_levels() -> void:
	assert_int(Levels.level_count()).is_equal(40)

func test_every_jump_can_be_made() -> void:
	var bad := []
	for level_index in Levels.level_count():
		var level_data: Dictionary = Levels.LEVELS[level_index]
		for piece in level_data.pieces:
			# Hop's 70 is the tallest the blob has always managed
			if piece.kind == "step" and absi(piece.rise) > 70:
				bad.append("%s: a step of %d" % [level_data.name, piece.rise])
			# 160 only works with a long flat run-up, so the newer levels stop at 150
			var widest_gap := 160 if level_index < 9 else 150
			if piece.kind == "gap" and piece.width > widest_gap:
				bad.append("%s: a gap of %d" % [level_data.name, piece.width])
	assert_array(bad).is_empty()

func test_every_level_starts_with_room_to_run_up() -> void:
	var bad := Levels.LEVELS.filter(func(l): return l.pieces[0].kind != "flat" or l.pieces[0].length < HillsLevelScript.BLOB_START_X + 300)
	assert_array(bad.map(func(l): return l.name)).is_empty()

func test_every_level_has_a_known_paint_and_scene() -> void:
	assert_array(Levels.LEVELS.filter(func(l): return not PaintMixing.COLOURS.has(l.paint)).map(func(l): return l.name)).is_empty()
	assert_array(Levels.LEVELS.filter(func(l): return not Scenes.SCENES.has(l.get("scene", "meadow"))).map(func(l): return l.name)).is_empty()

# Two pots: three always mixed to brown
func test_every_level_has_two_pots_that_change_the_paint_and_its_own_comes_last() -> void:
	var bad := []
	for level_index in Levels.level_count():
		var level_data: Dictionary = Levels.LEVELS[level_index]
		var pot_paints: Array = Levels.pot_paints(level_index)
		if pot_paints.size() != 2 or pot_paints.back() != level_data.pickup:
			bad.append("%s: pots %s should be one extra then its own %s" % [level_data.name, pot_paints, level_data.pickup])
		for paint in pot_paints:
			if PaintMixing.mix(level_data.paint, paint) == level_data.paint:
				bad.append("%s: the %s pot doesn't change %s" % [level_data.name, paint, level_data.paint])
	assert_array(bad).is_empty()

# Levels 21-40 are a little harder: at least as many jumps as the middle of 11-20
func test_the_later_levels_have_at_least_as_many_jumps_as_the_middle_ones() -> void:
	var jump_counts := []
	for level_data in Levels.LEVELS:
		jump_counts.append(level_data.pieces.filter(func(p): return p.kind == "step" or p.kind == "gap").size())
	var middle := jump_counts.slice(10, 20)
	middle.sort()
	var median: int = middle[middle.size() / 2]
	var bad := []
	for level_index in range(20, Levels.level_count()):
		if jump_counts[level_index] < median:
			bad.append("level %d has %d jumps" % [level_index + 1, jump_counts[level_index]])
	assert_array(bad).override_failure_message("wanted at least %d jumps: %s" % [median, bad]).is_empty()

# Every scene has everything the backdrop and ground draw with
func test_every_scene_has_the_same_settings_as_the_meadow() -> void:
	for scene_name in Scenes.SCENES:
		assert_array(Scenes.SCENES[scene_name].keys()).override_failure_message("the %s scene's settings" % scene_name) \
			.is_equal(Scenes.SCENES.meadow.keys())
