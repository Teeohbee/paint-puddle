extends GdUnitTestSuite
# ClockRungs: the eight rungs of the ladder, in the order schools teach them.

const EVERY_RUNG: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
const SEVEN_AM: int = 7 * 60

func test_there_are_eight_rungs() -> void:
	assert_int(ClockRungs.RUNG_COUNT).is_equal(8)

func test_each_rung_teaches_its_own_times() -> void:
	assert_array(ClockRungs.minutes_past_the_hour(1)).contains_exactly([0])
	assert_array(ClockRungs.minutes_past_the_hour(2)).contains_exactly([30])
	assert_array(ClockRungs.minutes_past_the_hour(3)).contains_exactly([0, 30])
	assert_array(ClockRungs.minutes_past_the_hour(4)).contains_exactly([15])
	assert_array(ClockRungs.minutes_past_the_hour(5)).contains_exactly([45])
	assert_array(ClockRungs.minutes_past_the_hour(6)).contains_exactly([5, 10, 20, 25])
	assert_array(ClockRungs.minutes_past_the_hour(7)).contains_exactly([35, 40, 50, 55])
	var single_minutes: Array = ClockRungs.minutes_past_the_hour(8)
	assert_int(single_minutes.size()).is_equal(48)
	for minute in single_minutes:
		assert_int(minute % 5).override_failure_message("rung 8 is the minutes between the fives, not %d" % minute).is_not_equal(0)

func test_one_press_winds_by_the_rungs_step() -> void:
	var expected_steps: Array[int] = [60, 30, 30, 15, 15, 5, 5, 1]
	for rung in EVERY_RUNG:
		assert_int(ClockRungs.step_minutes(rung)).override_failure_message("rung %d step" % rung).is_equal(expected_steps[rung - 1])

func test_every_rungs_times_are_reachable_in_whole_steps_from_7_am() -> void:
	for rung in EVERY_RUNG:
		for time in ClockRungs.times_of_the_day(rung):
			assert_int((time - SEVEN_AM) % ClockRungs.step_minutes(rung)).override_failure_message(
				"rung %d can't wind to %s" % [rung, ClockTime.digital_text(time)]).is_equal(0)

func test_times_of_the_day_cover_both_halves_of_the_day() -> void:
	var rung_1_times: Array[int] = ClockRungs.times_of_the_day(1)
	assert_int(rung_1_times.size()).is_equal(24)
	assert_array(rung_1_times).contains([3 * 60, 15 * 60])

func test_the_minute_hand_is_hidden_on_rungs_1_and_2_only() -> void:
	for rung in EVERY_RUNG:
		assert_bool(ClockRungs.shows_minute_hand(rung)).override_failure_message("rung %d" % rung).is_equal(rung >= 3)

func test_hand_names_drop_little_and_big_from_rung_4() -> void:
	assert_str(ClockRungs.hour_hand_name(3)).is_equal("little hour hand")
	assert_str(ClockRungs.minute_hand_name(3)).is_equal("big minute hand")
	assert_str(ClockRungs.hour_hand_name(4)).is_equal("hour hand")
	assert_str(ClockRungs.minute_hand_name(8)).is_equal("minute hand")

func test_each_rung_cleared_unlocks_the_next_tricky_face() -> void:
	assert_array(ClockRungs.tricky_faces_unlocked(0)).is_empty()
	assert_array(ClockRungs.tricky_faces_unlocked(1)).contains_exactly(["four numbers"])
	assert_array(ClockRungs.tricky_faces_unlocked(8)).contains_exactly(
		["four numbers", "kitchen", "square", "puddle", "marks only", "twin hands", "wristwatch", "bare"])
	assert_array(ClockRungs.tricky_faces_unlocked(99)).has_size(8)

func test_every_rung_has_a_short_title() -> void:
	for rung in EVERY_RUNG:
		assert_str(ClockRungs.title(rung)).is_not_empty()

func test_the_climbing_rung_is_the_lowest_not_cleared() -> void:
	assert_int(ClockRungs.climbing_rung(0)).is_equal(1)
	assert_int(ClockRungs.climbing_rung(7)).is_equal(8)
	assert_int(ClockRungs.climbing_rung(8)).override_failure_message("nothing left to climb").is_equal(0)

func test_cleared_rungs_and_the_climbing_rung_are_open() -> void:
	assert_bool(ClockRungs.is_open(1, 0, false)).is_true()
	assert_bool(ClockRungs.is_open(2, 0, false)).is_false()
	assert_bool(ClockRungs.is_open(3, 2, false)).is_true()
	assert_bool(ClockRungs.is_open(8, 0, true)).override_failure_message("open all rungs opens every rung").is_true()

func test_every_rung_has_an_example_time_of_its_own() -> void:
	for rung in EVERY_RUNG:
		var example: int = ClockRungs.example_minutes(rung)
		assert_bool(ClockRungs.minutes_past_the_hour(rung).has(example % 60)).override_failure_message("rung %d" % rung).is_true()

func test_tricky_replays_deal_only_unlocked_faces() -> void:
	assert_array(ClockRungs.tricky_faces_for(2, 3, false)).contains_exactly(["four numbers", "kitchen", "square"])
	assert_array(ClockRungs.tricky_faces_for(1, 0, true)).has_size(8)

func test_tricky_rung_8_never_deals_the_bare_face() -> void:
	assert_array(ClockRungs.tricky_faces_for(8, 8, false)).not_contains(["bare"])
	assert_array(ClockRungs.tricky_faces_for(8, 0, true)).not_contains(["bare"])
	assert_array(ClockRungs.tricky_faces_for(7, 8, false)).contains(["bare"])

func test_only_cleared_rungs_open_for_tricky_replays() -> void:
	assert_bool(ClockRungs.is_open_for_tricky(2, 2, false)).is_true()
	assert_bool(ClockRungs.is_open_for_tricky(3, 2, false)).override_failure_message("the climbing rung isn't cleared yet").is_false()
	assert_bool(ClockRungs.is_open_for_tricky(8, 0, true)).is_true()
