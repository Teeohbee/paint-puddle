extends GameSuite
# The first time a rung opens, a short guided bit shows its one new idea before the cards: the blob
# winds the clock and says how to read it, then it's his turn to copy, with ghost hands showing. It's
# saved, so later visits go straight to the cards. Rung 3 first brings the minute hand on; rung 8
# first counts single minutes.

func open_rung(rung: int) -> ClockMode:
	GameSettings.set_setting("open_all_clock_rungs", 1)
	ClockMode.rung_to_play = rung
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	return get_tree().current_scene

func seconds(how_long: float) -> void:
	await frames(roundi(how_long * 60))

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func test_rung_1_shows_then_lets_him_copy_then_deals_the_cards() -> void:
	var mode: ClockMode = await open_rung(1)
	check(mode.task_banner.main_text == "Watch!", "the blob shows first: '%s'" % mode.task_banner.main_text)
	check(mode.task_banner.small_text == "The hour hand points at the 3. It's 3 o'clock!", "and says how: '%s'" % mode.task_banner.small_text)
	check(not mode.player_can_wind, "hands off while it shows")
	await seconds(ClockTaskRunner.SECONDS_TO_WIND_IN_THE_INTRO + ClockTaskRunner.SECONDS_TO_WATCH + 0.5)
	check(ClockTime.faces_match(mode.minutes_of_the_day(), 3 * 60), "the clock wound to 3: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	check(mode.task_banner.main_text == "Your turn - wind it to 5 o'clock", "then his turn: '%s'" % mode.task_banner.main_text)
	check(ClockTime.faces_match(mode.clock_face.ghost_minutes, 5 * 60), "with ghost hands on the 5")
	check(mode.player_can_wind, "and he can wind")
	await tap("act")
	check(mode.clock_face.head_shake > 0.0, "pressing A too soon is a gentle no")
	await tap("move_right")
	await tap("move_right")
	await tap("act")
	check(mode.task_banner.main_text.begins_with("Yes!"), "5 o'clock is right: '%s'" % mode.task_banner.main_text)
	check(GameSettings.get_progress("clock_first_try_run") == 0, "the copy turn doesn't count towards moving up")
	await seconds(ClockTaskRunner.SECONDS_TO_CELEBRATE + 0.5)
	check(mode.task_runner.current_card != null and mode.task_runner.current_card.is_read, "then the first card")
	check(GameSettings.get_progress("clock_rung_intros_seen") == 1, "the intro is saved as seen")

func test_the_second_time_goes_straight_to_the_cards() -> void:
	GameSettings.record_progress("clock_rung_intros_seen", 1)
	var mode: ClockMode = await open_rung(1)
	check(mode.task_runner.current_card != null, "straight into the first card")
	check(mode.controls_hint.caption == "", "no words under the controls: '%s'" % mode.controls_hint.caption)
	check(mode.task_runner.current_card.is_read and mode.controls_hint.glow.has("left"), "a read card shows left, to pick an answer")
	check(mode.job_ring.job == ClockJob.Job.LOOK and mode.task_banner.job == ClockJob.Job.LOOK, "a read card wears the look job")
	mode.task_runner.play_set_card()
	check(not mode.controls_hint.glow.has("left"), "a set card hides it again: only right winds")
	check(mode.job_ring.job == ClockJob.Job.WIND and mode.task_banner.job == ClockJob.Job.WIND, "a set card wears the wind job")

func test_rung_3_brings_the_minute_hand_on_first() -> void:
	GameSettings.record_progress("clock_rung_intros_seen", 2)
	var mode: ClockMode = await open_rung(3)
	check(mode.task_banner.main_text == "Meet the big minute hand!", "the intro: '%s'" % mode.task_banner.main_text)
	check(mode.clock_face.minute_hand_reach == 0.0, "the minute hand isn't on yet")
	await seconds(2.2)
	check(mode.clock_face.minute_hand_reach > 0.95, "it slides on")
	await seconds(7.0)
	check(mode.task_banner.main_text == "Watch!", "then the blob shows: '%s'" % mode.task_banner.main_text)

func test_rung_8_counts_minutes_with_the_marks_lighting_up() -> void:
	GameSettings.record_progress("clock_rung_intros_seen", 7)
	var mode: ClockMode = await open_rung(8)
	check(mode.task_banner.main_text == "Hold to go in fives. Tap to count the minutes.", "the intro: '%s'" % mode.task_banner.main_text)
	check(mode.controls_hint.caption == "Tap: 1 minute · Hold: 5 minutes", "the controls hint says it too")
	await seconds(4.4)
	check(mode.clock_face.lit_minutes == [16, 17, 18], "16, 17 and 18 light up: %s" % [mode.clock_face.lit_minutes])
