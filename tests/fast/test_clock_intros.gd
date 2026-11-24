extends GameSuite
# Rungs 3 and 8 open with a short intro: the big minute hand arriving, and counting single minutes.

func open_rung(rung: int) -> ClockMode:
	GameSettings.set_setting("open_all_clock_rungs", 1)
	ClockMode.rung_to_play = rung
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	return get_tree().current_scene

func seconds(how_long: float) -> void:
	await frames(roundi(how_long * 60))

func test_rung_3_brings_the_minute_hand_on_then_plays() -> void:
	var mode: ClockMode = await open_rung(3)
	check(mode.task_banner.main_text == "Meet the big minute hand!", "the intro: '%s'" % mode.task_banner.main_text)
	check(mode.clock_face.minute_hand_reach == 0.0, "the minute hand isn't on yet")
	check(not mode.player_can_wind, "hands off during the intro")
	await seconds(2.2)
	check(mode.clock_face.minute_hand_reach > 0.95, "it slides on")
	await seconds(7.0)
	check(mode.task_runner.current_card != null and mode.task_runner.current_card.is_read, "then the first card")
	check(mode.clock_face.minute_hand_reach == 1.0, "with the minute hand on")

func test_rung_8_counts_minutes_with_the_marks_lighting_up() -> void:
	var mode: ClockMode = await open_rung(8)
	check(mode.task_banner.main_text == "Hold to go in fives. Tap to count the minutes.", "the intro: '%s'" % mode.task_banner.main_text)
	check(mode.controls_hint.caption == "Tap: 1 minute · Hold: 5 minutes", "the controls hint says it too")
	await seconds(4.4)
	check(mode.clock_face.lit_minutes == [16, 17, 18], "16, 17 and 18 light up: %s" % [mode.clock_face.lit_minutes])
	await seconds(3.0)
	check(mode.task_runner.current_card != null, "then the first card")
	check(mode.clock_face.lit_minutes.is_empty(), "and the marks go out")

func test_other_rungs_have_no_intro_and_the_plain_caption() -> void:
	var mode: ClockMode = await open_rung(4)
	check(mode.task_runner.current_card != null, "straight into the first card")
	check(mode.controls_hint.caption == ClockMode.CONTROLS, "the wind-on caption: '%s'" % mode.controls_hint.caption)
