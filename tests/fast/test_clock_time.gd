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
