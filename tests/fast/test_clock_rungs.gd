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

func test_the_digital_helper_shows_on_rungs_4_to_6_only() -> void:
	for rung in EVERY_RUNG:
		assert_bool(ClockRungs.shows_digital_helper(rung)).override_failure_message("rung %d" % rung).is_equal(rung >= 4 and rung <= 6)

func test_each_rung_cleared_unlocks_the_next_tricky_face() -> void:
	assert_array(ClockRungs.tricky_faces_unlocked(0)).is_empty()
	assert_array(ClockRungs.tricky_faces_unlocked(1)).contains_exactly(["four numbers"])
	assert_array(ClockRungs.tricky_faces_unlocked(8)).contains_exactly(
		["four numbers", "kitchen", "square", "puddle", "marks only", "twin hands", "wristwatch", "bare"])
	assert_array(ClockRungs.tricky_faces_unlocked(99)).has_size(8)

func test_every_rung_has_a_short_title() -> void:
	for rung in EVERY_RUNG:
		assert_str(ClockRungs.title(rung)).is_not_empty()
