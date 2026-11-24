extends GameSuite
# Play with the clock: no cards and no wrong, just winding the day on and watching the house. Every
# time it opens, an intro curls a 1-12 number line into the clock face and the hour hand ticks
# round to the morning; any button skips it. It uses the climbing rung's hands and step.

func open_free_play(skip_intro: bool = true) -> ClockMode:
	ClockMode.free_play = true
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	if skip_intro:
		mode.intro.skip()
		await frames(2)
	return mode

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func test_free_play_has_no_cards() -> void:
	var mode: ClockMode = await open_free_play()
	check(mode.task_runner == null, "no task runner")
	check(not mode.answer_cards.visible, "no answers")
	check(mode.task_banner.main_text == ClockMode.YOUR_TURN_WORDS, "the banner only says it's his turn: '%s'" % mode.task_banner.main_text)

func test_right_and_a_both_wind_on_by_the_rung_s_step() -> void:
	var mode: ClockMode = await open_free_play()
	check(mode.minutes_of_the_day() == 7 * 60, "starts at 7 in the morning: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("move_right")
	check(mode.minutes_of_the_day() == 8 * 60, "right winds on an hour on rung 1: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("act")
	check(mode.minutes_of_the_day() == 9 * 60, "and so does A: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("move_left")
	check(mode.minutes_of_the_day() == 9 * 60, "left does nothing")

func test_the_house_acts_out_the_day_as_it_winds() -> void:
	var mode: ClockMode = await open_free_play()
	for step in 12:
		await tap("move_right")
	await frames(30)
	check(mode.house.moment["name"] == "Bedtime story", "at 7 in the evening it's the bedtime story: %s" % mode.house.moment["name"])

func test_only_the_climbing_rung_s_hands_show() -> void:
	var mode: ClockMode = await open_free_play()
	check(not mode.clock_face.shows_minute_hand, "rung 1: the hour hand alone")

func test_the_intro_plays_by_itself_and_ends_in_time() -> void:
	var mode: ClockMode = await open_free_play(false)
	check(mode.intro.is_playing(), "the intro plays on opening")
	check(not mode.player_can_wind, "no winding while it plays")
	var intro_seconds: float = ClockNumberLineIntro.SECONDS_TO_SHOW_THE_LINE + ClockNumberLineIntro.SECONDS_TO_HOLD_THE_LINE \
		+ ClockNumberLineIntro.SECONDS_TO_CURL + ClockNumberLineIntro.SECONDS_PER_TICK * (ClockNumberLineIntro.STARTING_HOUR + 1)
	await frames(roundi(60 * (intro_seconds - 0.5)))
	check(mode.intro.is_playing(), "still playing just before %.1f s, slow enough to follow" % intro_seconds)
	await frames(60)
	check(not mode.intro.is_playing(), "it's over by %.1f s" % (intro_seconds + 0.5))
	check(mode.player_can_wind, "then winding is on")
	check(mode.minutes_of_the_day() == 7 * 60, "at 7 in the morning: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))

func test_any_button_skips_the_intro_without_winding() -> void:
	var mode: ClockMode = await open_free_play(false)
	await frames(10)
	await tap("move_right")
	check(not mode.intro.is_playing(), "right skips the intro")
	await frames(4)
	check(mode.minutes_of_the_day() == 7 * 60, "and doesn't also wind: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("move_right")
	check(mode.minutes_of_the_day() == 8 * 60, "the next press winds: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))

func test_the_intro_plays_every_time() -> void:
	var mode: ClockMode = await open_free_play()
	mode = await open_free_play(false)
	check(mode.intro.is_playing(), "the second visit plays it too")

func test_the_controls_hint_shows_no_left_and_no_words() -> void:
	var mode: ClockMode = await open_free_play()
	check(mode.controls_hint.caption == "", "no caption: '%s'" % mode.controls_hint.caption)
	check(not mode.controls_hint.glow.has("left"), "no left arrow in free play, so left never lights")
	check(mode.controls_hint.glow.has("right") and mode.controls_hint.glow.has("jump"), "right and A still show")

func test_when_the_intro_ends_it_is_his_turn_until_he_winds() -> void:
	var mode: ClockMode = await open_free_play()
	check(mode.job_ring.job == ClockJob.Job.WIND, "the wind ring shows")
	check(mode.task_banner.main_text == ClockMode.YOUR_TURN_WORDS and mode.your_turn_showing, "and says it's his turn: '%s'" % mode.task_banner.main_text)
	check(mode.clock_face.cheer > 0.0, "the blob cheers")
	await tap("move_right")
	await frames(2)
	check(not mode.your_turn_showing, "the banner goes on the first wind")
	check(mode.job_ring.job == ClockJob.Job.WIND, "the ring stays: winding is the job")

func test_the_number_line_has_no_0() -> void:
	var mode: ClockMode = await open_free_play(false)
	check(mode.intro.spot_on_the_line(1).x < mode.intro.spot_on_the_line(2).x, "1 starts the line")
	check(is_equal_approx(mode.intro.spot_on_the_line(12).x, ClockNumberLineIntro.LINE_CENTRE_X + ClockNumberLineIntro.LINE_HALF_WIDTH), "12 ends it")

func test_the_12_on_the_line_stays_clear_of_the_house() -> void:
	var mode: ClockMode = await open_free_play(false)
	var font: Font = mode.clock_face.game_font()
	var twelve_width: float = font.get_string_size("12", HORIZONTAL_ALIGNMENT_LEFT, -1, ClockNumberLineIntro.LINE_NUMBER_FONT_SIZE).x
	var twelve_right: float = ClockMode.CLOCK_CENTRE.x + mode.intro.spot_on_the_line(12).x + twelve_width / 2.0
	check(twelve_right < ClockMode.HOUSE_BOX.position.x - 10.0, "the 12 ends at %.0f, the house starts at %.0f" % [twelve_right, ClockMode.HOUSE_BOX.position.x])
	var one_width: float = font.get_string_size("1", HORIZONTAL_ALIGNMENT_LEFT, -1, ClockNumberLineIntro.LINE_NUMBER_FONT_SIZE).x
	check(ClockMode.CLOCK_CENTRE.x + mode.intro.spot_on_the_line(1).x - one_width / 2.0 > 20.0, "and the 1 is on the screen")
