extends GdUnitTestSuite
# ClockTime: the clock's arithmetic. A time is minutes since midnight, 0 to 1439, so the clock
# winds through a whole 24-hour day and one lap of the face is half of it.

func minutes_of(hour_of_the_day: int, minute: int) -> int:
	return hour_of_the_day * 60 + minute


# ---- winding

func test_winding_forwards_by_a_step() -> void:
	assert_int(ClockTime.wound(minutes_of(3, 0), 60)).is_equal(minutes_of(4, 0))
	assert_int(ClockTime.wound(minutes_of(3, 0), 5)).is_equal(minutes_of(3, 5))
	assert_int(ClockTime.wound(minutes_of(3, 55), 15)).is_equal(minutes_of(4, 10))

func test_winding_backwards_by_a_step() -> void:
	assert_int(ClockTime.wound(minutes_of(3, 0), -30)).is_equal(minutes_of(2, 30))
	assert_int(ClockTime.wound(minutes_of(3, 17), -1)).is_equal(minutes_of(3, 16))

func test_winding_carries_on_past_noon_into_the_afternoon() -> void:
	assert_int(ClockTime.wound(minutes_of(11, 30), 60)).is_equal(minutes_of(12, 30))

func test_winding_wraps_round_midnight_both_ways() -> void:
	assert_int(ClockTime.wound(minutes_of(23, 30), 60)).is_equal(minutes_of(0, 30))
	assert_int(ClockTime.wound(minutes_of(0, 15), -30)).is_equal(minutes_of(23, 45))
	assert_int(ClockTime.wound(0, -ClockTime.MINUTES_IN_A_DAY * 2)).is_equal(0)


# ---- the hands, as a fraction of one lap from 12, clockwise

func test_the_minute_hand_points_at_the_minutes() -> void:
	assert_float(ClockTime.minute_hand_turns(minutes_of(3, 0))).is_equal_approx(0.0, 0.0001)
	assert_float(ClockTime.minute_hand_turns(minutes_of(3, 15))).is_equal_approx(0.25, 0.0001)
	assert_float(ClockTime.minute_hand_turns(minutes_of(15, 45))).is_equal_approx(0.75, 0.0001)

func test_the_hour_hand_creeps_with_the_minute_hand() -> void:
	# 3:30 sits halfway between the 3 and the 4
	assert_float(ClockTime.hour_hand_turns(minutes_of(3, 30))).is_equal_approx(3.5 / 12.0, 0.0001)
	# 11:55 is nearly at the 12, not at the 11
	assert_float(ClockTime.hour_hand_turns(minutes_of(11, 55))).is_equal_approx((11.0 + 55.0 / 60.0) / 12.0, 0.0001)

func test_the_afternoon_looks_the_same_as_the_morning() -> void:
	assert_float(ClockTime.hour_hand_turns(minutes_of(15, 20))).is_equal_approx(ClockTime.hour_hand_turns(minutes_of(3, 20)), 0.0001)
	assert_float(ClockTime.hour_hand_turns(minutes_of(0, 0))).is_equal_approx(0.0, 0.0001)
	assert_float(ClockTime.hour_hand_turns(minutes_of(12, 0))).is_equal_approx(0.0, 0.0001)


# ---- saying the time: numbers in digits, the rest in words

func test_o_clock_and_half_past() -> void:
	assert_str(ClockTime.time_words(minutes_of(3, 0))).is_equal("3 o'clock")
	assert_str(ClockTime.time_words(minutes_of(3, 30))).is_equal("half past 3")

func test_quarters() -> void:
	assert_str(ClockTime.time_words(minutes_of(3, 15))).is_equal("quarter past 3")
	assert_str(ClockTime.time_words(minutes_of(3, 45))).is_equal("quarter to 4")

func test_fives_say_past_up_to_half_past_and_to_after_it() -> void:
	assert_str(ClockTime.time_words(minutes_of(3, 5))).is_equal("5 past 3")
	assert_str(ClockTime.time_words(minutes_of(3, 25))).is_equal("25 past 3")
	assert_str(ClockTime.time_words(minutes_of(3, 35))).is_equal("25 to 4")
	assert_str(ClockTime.time_words(minutes_of(3, 40))).is_equal("20 to 4")
	assert_str(ClockTime.time_words(minutes_of(3, 55))).is_equal("5 to 4")

func test_single_minutes_say_minutes() -> void:
	assert_str(ClockTime.time_words(minutes_of(3, 17))).is_equal("17 minutes past 3")
	assert_str(ClockTime.time_words(minutes_of(3, 1))).is_equal("1 minute past 3")
	assert_str(ClockTime.time_words(minutes_of(3, 43))).is_equal("17 minutes to 4")
	assert_str(ClockTime.time_words(minutes_of(3, 59))).is_equal("1 minute to 4")

func test_the_hours_are_1_to_12_never_0_or_13() -> void:
	assert_str(ClockTime.time_words(minutes_of(0, 0))).is_equal("12 o'clock")
	assert_str(ClockTime.time_words(minutes_of(12, 30))).is_equal("half past 12")
	assert_str(ClockTime.time_words(minutes_of(15, 0))).is_equal("3 o'clock")
	# "to" names the next hour, round past 12 and past midnight
	assert_str(ClockTime.time_words(minutes_of(12, 45))).is_equal("quarter to 1")
	assert_str(ClockTime.time_words(minutes_of(23, 40))).is_equal("20 to 12")
	assert_str(ClockTime.time_words(minutes_of(11, 50))).is_equal("10 to 12")


# ---- which half of the day: the part of the day in words, am/pm small alongside

func test_parts_of_the_day_change_at_6_12_5_and_8() -> void:
	var expected_parts: Dictionary = {
		minutes_of(5, 59): "night", minutes_of(6, 0): "morning",
		minutes_of(11, 59): "morning", minutes_of(12, 0): "afternoon",
		minutes_of(16, 59): "afternoon", minutes_of(17, 0): "evening",
		minutes_of(19, 59): "evening", minutes_of(20, 0): "night",
		minutes_of(0, 0): "night",
	}
	for minutes in expected_parts:
		assert_str(ClockTime.part_of_the_day(minutes)).override_failure_message(
			"%s should be %s" % [ClockTime.digital_text(minutes), expected_parts[minutes]]).is_equal(expected_parts[minutes])

func test_am_before_noon_and_pm_from_it() -> void:
	assert_str(ClockTime.am_or_pm(minutes_of(0, 0))).is_equal("am")
	assert_str(ClockTime.am_or_pm(minutes_of(11, 59))).is_equal("am")
	assert_str(ClockTime.am_or_pm(minutes_of(12, 0))).is_equal("pm")
	assert_str(ClockTime.am_or_pm(minutes_of(23, 59))).is_equal("pm")

func test_digital_time_is_on_the_12_hour_clock() -> void:
	assert_str(ClockTime.digital_text(minutes_of(3, 5))).is_equal("3:05")
	assert_str(ClockTime.digital_text(minutes_of(15, 45))).is_equal("3:45")
	assert_str(ClockTime.digital_text(minutes_of(0, 0))).is_equal("12:00")
	assert_str(ClockTime.digital_text(minutes_of(12, 30))).is_equal("12:30")

func test_the_time_with_its_part_of_the_day() -> void:
	# o'clock drops the "o'clock": "6 in the evening"
	assert_str(ClockTime.time_in_the_day_words(minutes_of(18, 0))).is_equal("6 in the evening")
	assert_str(ClockTime.time_in_the_day_words(minutes_of(15, 40))).is_equal("20 to 4 in the afternoon")
	assert_str(ClockTime.time_in_the_day_words(minutes_of(8, 30))).is_equal("half past 8 in the morning")
	assert_str(ClockTime.time_in_the_day_words(minutes_of(2, 0))).is_equal("2 at night")
