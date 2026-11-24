extends GameSuite
# Clock mode's cards: set the hands and press A, or pick the time the clock shows. Time only goes
# forward, so a card's time is the next time the face shows it, and there's no am/pm anywhere.

func open_with_deck(rung: int, cards: Array[ClockCard]) -> ClockMode:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	mode.task_runner.start_deck(rung, cards)
	await frames(2)
	return mode

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func seconds(how_long: float) -> void:
	await frames(roundi(how_long * 60))

func set_card(hour_of_the_day: int, minute: int) -> ClockCard:
	return ClockCard.new(false, hour_of_the_day * 60 + minute)

func read_card(hour_of_the_day: int, minute: int) -> ClockCard:
	return ClockCard.new(true, hour_of_the_day * 60 + minute)


# ---- set cards

func test_a_set_card_asks_for_a_time_with_its_moment_and_no_am_or_pm() -> void:
	var mode: ClockMode = await open_with_deck(3, [set_card(8, 30), set_card(9, 0)])
	check(mode.task_banner.main_text == "Breakfast - make it half past 8", "the card names the moment and the time: '%s'" % mode.task_banner.main_text)
	check(mode.task_banner.small_text == "", "nothing small underneath: '%s'" % mode.task_banner.small_text)

func test_setting_the_right_time_and_pressing_a_moves_on() -> void:
	var mode: ClockMode = await open_with_deck(3, [set_card(8, 0), set_card(9, 0)])
	await tap("move_right")
	await tap("move_right")
	check(mode.minutes_of_the_day() == 8 * 60, "wound to 8: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("act")
	check(mode.task_banner.main_text.begins_with("Yes!"), "a cheer: '%s'" % mode.task_banner.main_text)
	await seconds(2.0)
	check(mode.task_runner.card_index == 1 and mode.task_banner.main_text == "Off to the park - make it 9 o'clock", "on to the next card: '%s'" % mode.task_banner.main_text)
	check(mode.minutes_of_the_day() == 8 * 60, "the day carries on from where the last card ended")

func test_a_set_card_asks_for_the_next_time_round() -> void:
	# The day starts at 7am, so "7 o'clock" is the next one: the evening's, a whole lap on
	var mode: ClockMode = await open_with_deck(1, [set_card(7, 0), set_card(9, 0)])
	check(mode.task_runner.target_minutes == 19 * 60, "the target is 7 in the evening: %d" % mode.task_runner.target_minutes)
	check(mode.task_banner.main_text == "Bedtime story - make it 7 o'clock", "named by the evening's moment: '%s'" % mode.task_banner.main_text)
	await tap("act")
	check(mode.task_runner.card_index == 0, "pressing A without winding isn't it")
	for step in 12:
		await tap("move_right")
	await tap("act")
	check(mode.task_banner.main_text.begins_with("Yes!"), "a lap on, it is: '%s'" % mode.task_banner.main_text)

func test_going_round_again_still_reads_right() -> void:
	# Overshoot 9 o'clock and wind on to 9 at night: the face shows 9, so that's right too
	var mode: ClockMode = await open_with_deck(1, [set_card(9, 0), set_card(10, 0)])
	for step in 14:
		await tap("move_right")
	check(mode.minutes_of_the_day() == 21 * 60, "at 9pm: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await tap("act")
	check(mode.task_banner.main_text.begins_with("Yes!"), "the face reads 9 o'clock: '%s'" % mode.task_banner.main_text)

func test_a_second_miss_glows_the_number_to_aim_for() -> void:
	var mode: ClockMode = await open_with_deck(3, [set_card(9, 30), set_card(9, 0)])
	await tap("act")
	check(mode.clock_face.glow == 0.0, "no glow after one miss")
	await tap("act")
	check(mode.clock_face.glow > 0.0 and mode.clock_face.glowing_number == 9, "the 9 glows after two: %d" % mode.clock_face.glowing_number)
	check(mode.clock_face.glowing_minute == -1, "only the number on rung 3")
	await tap("move_right")
	await seconds(0.6)
	check(mode.clock_face.glow == 0.0, "moving the hands fades the glow")

func test_from_rung_4_the_minute_mark_glows_too_and_to_times_glow_the_next_hour() -> void:
	var mode: ClockMode = await open_with_deck(5, [set_card(9, 45), set_card(9, 0)])
	await tap("act")
	await tap("act")
	check(mode.clock_face.glowing_number == 10 and mode.clock_face.glowing_minute == 45, "quarter to 10 glows the 10 and the 45 mark: %d, %d" % [mode.clock_face.glowing_number, mode.clock_face.glowing_minute])

# ---- read cards

func test_a_read_card_winds_the_clock_itself_then_offers_three_answers() -> void:
	var mode: ClockMode = await open_with_deck(3, [read_card(15, 30), set_card(9, 0)])
	check(mode.task_banner.main_text == "What time is it?", "the card asks: '%s'" % mode.task_banner.main_text)
	check(not mode.answer_cards.visible, "no answers while the clock winds")
	await tap("move_right")
	await seconds(1.7)
	check(mode.minutes_of_the_day() == 15 * 60 + 30, "the clock wound itself forward to 3:30 pm: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	check(mode.wound_minutes > 7 * 60, "forwards, not back")
	check(mode.answer_cards.visible and mode.answer_cards.answers.size() == 3, "three answers")

func test_picking_the_right_answer_moves_on() -> void:
	var mode: ClockMode = await open_with_deck(3, [read_card(15, 30), set_card(9, 0)])
	await seconds(1.7)
	var right_index: int = mode.answer_cards.answers.find(15 * 60 + 30)
	for move in right_index:
		await tap("move_right")
	check(mode.answer_cards.chosen_index == right_index, "moved onto the right answer")
	await tap("act")
	check(not mode.answer_cards.visible and mode.task_banner.main_text.begins_with("Yes!"), "a cheer and the answers go")
	await seconds(2.0)
	check(mode.task_runner.card_index == 1, "on to the next card")

func test_a_wrong_pick_shows_its_time_winds_back_and_fades_away() -> void:
	var mode: ClockMode = await open_with_deck(3, [read_card(15, 30), set_card(9, 0)])
	await seconds(1.7)
	var wrong_index: int = 0 if mode.answer_cards.answers[0] != 15 * 60 + 30 else 1
	var wrong_time: int = mode.answer_cards.answers[wrong_index]
	for move in wrong_index:
		await tap("move_right")
	await tap("act")
	await seconds(1.2)
	check(mode.minutes_of_the_day() == wrong_time, "the hands wind to the picked time: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	check(mode.task_banner.main_text == "That's %s." % ClockTime.time_words(wrong_time), "and say it: '%s'" % mode.task_banner.main_text)
	await seconds(3.0)
	check(mode.minutes_of_the_day() == 15 * 60 + 30, "then wind back")
	check(not mode.answer_cards.is_still_in(wrong_index), "the picked card has gone")
	check(mode.answer_cards.chosen_index != wrong_index, "and the choice moved off it")
	mode.answer_cards.move_choice(-1)
	mode.answer_cards.move_choice(1)
	check(mode.answer_cards.chosen_index != wrong_index, "it can't be picked again")

func test_a_deck_never_opens_on_a_set_card() -> void:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	check(mode.task_runner.current_card.is_read, "Clock mode opens on a read card")


# ---- the house

func test_the_blobs_only_change_on_confirm_but_the_sky_follows_the_hands() -> void:
	var mode: ClockMode = await open_with_deck(1, [set_card(19, 0), set_card(9, 0)])
	check(mode.house.moment["name"] == "A banana", "the day starts with a banana")
	for step in 12:
		await tap("move_right")
	await seconds(0.5)
	check(mode.house.moment["name"] == "A banana", "winding doesn't change the blobs")
	check(mode.house.live_minutes() > 17 * 60, "but the sky has moved on: %d" % mode.house.live_minutes())
	await tap("act")
	check(mode.house.moment["name"] == "Bedtime story", "confirming plays the moment")

func test_while_the_hands_are_away_from_the_moment_the_blobs_rest_by_the_sky() -> void:
	var mode: ClockMode = await open_with_deck(1, [set_card(4, 0), set_card(9, 0)])
	check(mode.house.acted_out_moment()["doing"] == "meal", "at 7am the blobs act out eating a banana")
	check(mode.house.highlighted_room() == "kitchen", "with the kitchen highlighted")
	check(not mode.house.is_dimmed("kitchen") and mode.house.is_dimmed("bedroom"), "and the other rooms dimmed")
	for step in 15:
		await tap("move_right")
	await seconds(0.5)
	check(mode.minutes_of_the_day() == 22 * 60, "wound on to 10 at night: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	check(mode.house.acted_out_moment()["doing"] == "asleep" and mode.house.acted_out_moment()["room"] == "bedroom", "in the dark they're asleep in bed: %s" % mode.house.acted_out_moment())
	check(mode.house.highlighted_room() == "", "and no room is highlighted, so nothing is given away")
	check(not mode.house.is_dimmed("bedroom") and not mode.house.is_dimmed("kitchen"), "nothing is dimmed")
	for step in 10:
		await tap("move_right")
	await seconds(0.5)
	check(mode.house.acted_out_moment()["doing"] == "sofa", "by day they rest on the sofa: %s" % mode.house.acted_out_moment())
	check(mode.house.highlighted_room() == "", "still nothing highlighted")

func test_a_garden_moment_dims_every_room_in_the_house() -> void:
	var mode: ClockMode = await open_with_deck(1, [set_card(9, 0), set_card(4, 0)])
	await tap("move_right")
	await tap("move_right")
	await seconds(0.5)
	await tap("act")
	check(mode.house.highlighted_room() == "garden", "9am is out in the garden: %s" % mode.house.highlighted_room())
	for room in ["bedroom", "bathroom", "kitchen", "living"]:
		check(mode.house.is_dimmed(room), "the %s is dimmed" % room)

func test_winding_round_to_the_moment_s_own_time_acts_it_out_again() -> void:
	var mode: ClockMode = await open_with_deck(1, [set_card(4, 0), set_card(9, 0)])
	await tap("move_right")
	await seconds(0.5)
	check(mode.house.acted_out_moment()["doing"] == "sofa", "away at 8am they rest on the sofa, not breakfast: %s" % mode.house.acted_out_moment())
	for step in 23:
		await tap("move_right")
	await seconds(0.5)
	check(mode.house.acted_out_moment()["meal"] == "banana", "round to 7am the next day, the banana again")

func test_a_read_card_shows_its_moment_once_the_clock_has_wound() -> void:
	var mode: ClockMode = await open_with_deck(3, [read_card(18, 30), set_card(9, 0)])
	check(mode.house.moment["name"] == "A banana", "still the last moment while the clock winds itself")
	await seconds(1.7)
	check(mode.house.moment["name"] == "Bath time", "then the blobs play the card's moment, so the house and sky agree: %s" % mode.house.moment["name"])

func test_a_wrong_read_pick_plays_its_moment_then_goes_back_to_the_cards() -> void:
	var mode: ClockMode = await open_with_deck(3, [read_card(18, 30), set_card(9, 0)])
	await seconds(1.7)
	var wrong_index: int = 0 if mode.answer_cards.answers[0] != 18 * 60 + 30 else 1
	var wrong_time: int = mode.answer_cards.answers[wrong_index]
	for move in wrong_index:
		await tap("move_right")
	await tap("act")
	check(mode.house.moment["name"] == DayMoments.moment_at(wrong_time)["name"], "the picked time's moment plays")
	await seconds(4.5)
	check(mode.house.moment["name"] == "Bath time", "then back to the card's own moment: %s" % mode.house.moment["name"])


# ---- answer card layout

func test_the_answer_cards_stay_clear_of_the_house() -> void:
	var mode: ClockMode = await open_with_deck(4, [read_card(14, 15), set_card(9, 0)])
	await seconds(1.7)
	var cards_right: float = mode.answer_cards.position.x + mode.answer_cards.size.x
	check(cards_right <= ClockMode.HOUSE_BOX.position.x, "the cards end at %d, before the house at %d" % [cards_right, ClockMode.HOUSE_BOX.position.x])
	check(mode.answer_cards.position.x >= 0.0, "and start on screen: %d" % mode.answer_cards.position.x)

func test_answer_cards_leave_out_the_digital_time_even_on_the_digital_rungs() -> void:
	var mode: ClockMode = await open_with_deck(4, [read_card(14, 15), set_card(9, 0)])
	await seconds(1.7)
	check(mode.answer_cards.size.y == ClockAnswerCards.CARD_SIZE.y, "the cards are the plain height: %d" % mode.answer_cards.size.y)
