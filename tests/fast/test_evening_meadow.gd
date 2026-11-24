extends GameSuite
# Medium is the Evening Meadow: deeper blue-green grass, a warm glow at the edges, pale flowers, hedge and
# bushes to match, fireflies instead of cloud shadows, and a calmer tune. Easy looks and sounds as before.
# No evening ground colour may hide a paint (green-on-green taught us that).

const MIN_DISTANCE_FROM_THE_GRASS: float = 0.35

var meadow

func open_meadow(difficulty: String) -> void:
	MeadowScript.difficulty = difficulty
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	meadow = get_tree().current_scene

func ground() -> MeadowGround:
	return meadow.find_children("*", "MeadowGround", false, false)[0]

func count_of(type: String) -> int:
	return meadow.find_children("*", type, false, false).size()

func test_easy_looks_as_before() -> void:
	var day := MeadowTheme.day()
	check(day.grass_top == Color(0.6, 0.84, 0.45) and day.grass_bottom == Color(0.48, 0.76, 0.38), "the day's grass is the old grass")
	check(day.hedge == Color(0.27, 0.55, 0.27) and day.bush_mid == Color(0.29, 0.6, 0.3), "and the old hedge and bushes")
	check(day.edge_glow.a == 0.0, "with no glow")
	await open_meadow(TaskRunner.EASY)
	check(ground().theme.name == "day", "Easy is the day meadow")
	check(count_of("CloudShadows") == 1 and count_of("Fireflies") == 0, "with cloud shadows")
	check(Music.wanted_track == "meadow", "and the Meadow tune")

func test_medium_is_the_evening_meadow() -> void:
	await open_meadow(TaskRunner.MEDIUM)
	check(ground().theme.name == "evening", "Medium is the evening meadow")
	for hedge in meadow.find_children("*", "Hedge", false, false):
		check(hedge.theme.name == "evening", "the hedge matches")
	for bush in meadow.find_children("*", "Bush", true, false):
		check(bush.theme.name == "evening", "and the bushes")
	check(count_of("Fireflies") == 1 and count_of("CloudShadows") == 0, "fireflies instead of cloud shadows")
	check(Music.wanted_track == "meadow_evening", "and a calmer tune: " + Music.wanted_track)

func test_the_evening_tune_is_calmer() -> void:
	var day: Dictionary = Music.TRACKS["meadow"]
	var evening: Dictionary = Music.TRACKS["meadow_evening"]
	check(evening.beats_per_minute < day.beats_per_minute, "slower")
	check(evening.melody_busyness < day.melody_busyness, "and less busy")

func test_every_paint_shows_up_on_the_evening_grass() -> void:
	var evening := MeadowTheme.evening()
	for paint_name in PaintMixing.paint_names():
		if not MeadowTask.can_be_made_in_the_meadow(paint_name):
			continue
		var paint: Color = PaintMixing.colour_of(paint_name)
		for grass in [evening.grass_top, evening.grass_bottom]:
			var distance: float = Vector3(paint.r - grass.r, paint.g - grass.g, paint.b - grass.b).length()
			check(distance >= MIN_DISTANCE_FROM_THE_GRASS, "%s stands out from the evening grass: %.2f" % [paint_name, distance])
