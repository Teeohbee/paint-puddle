extends GdUnitTestSuite
# DayMoments: what the household is doing at any time of the 24-hour day.

func test_every_hour_of_the_day_has_a_moment_in_a_real_room() -> void:
	for hour in 24:
		var moment: Dictionary = DayMoments.moment_at(hour * 60)
		assert_str(moment.get("name", "")).override_failure_message("hour %d" % hour).is_not_empty()
		assert_str(moment.get("that_is", "")).override_failure_message("hour %d" % hour).starts_with("That's")
		assert_bool(DayMoments.ROOMS.has(moment.get("room", ""))).override_failure_message("hour %d room %s" % [hour, moment.get("room")]).is_true()

func test_a_time_between_anchors_is_still_the_moment_that_started_last() -> void:
	assert_str(DayMoments.moment_at(18 * 60 + 40)["name"]).is_equal("Bath time")
	assert_str(DayMoments.moment_at(11 * 60 + 30)["name"]).is_equal("Playing outside")
	assert_str(DayMoments.moment_at(0)["name"]).is_equal("Shooting stars")

func test_a_moment_can_start_on_the_half_hour() -> void:
	assert_str(DayMoments.moment_at(6 * 60 + 29)["name"]).is_equal("The birds wake up")
	assert_str(DayMoments.moment_at(6 * 60 + 30)["name"]).is_equal("Wake up")
	assert_str(DayMoments.moment_at(7 * 60)["name"]).is_equal("A banana")
	assert_str(DayMoments.moment_at(7 * 60 + 30)["name"]).is_equal("Breakfast")
	assert_str(DayMoments.moment_at(18 * 60 + 15)["name"]).is_equal("Tea")
	assert_str(DayMoments.moment_at(18 * 60 + 30)["name"]).is_equal("Bath time")
	assert_str(DayMoments.moment_at(19 * 60)["name"]).is_equal("Bedtime story")
	assert_str(DayMoments.moment_at(19 * 60 + 30)["name"]).is_equal("Asleep")

func test_moments_are_listed_in_the_order_they_start() -> void:
	var moments: Array = DayMoments.all_moments()
	for index in range(1, moments.size()):
		assert_bool(DayMoments.starts_at(moments[index - 1]) < DayMoments.starts_at(moments[index])).override_failure_message("%s starts before %s" % [moments[index]["name"], moments[index - 1]["name"]]).is_true()

func test_the_night_is_as_busy_as_the_day() -> void:
	var night_moments: Dictionary = {}
	for hour in [20, 21, 22, 23, 0, 1, 2, 3, 4, 5]:
		night_moments[DayMoments.moment_at(hour * 60)["name"]] = true
	assert_int(night_moments.size()).override_failure_message("a different moment almost every night hour").is_greater_equal(9)

func test_meals_say_which_meal() -> void:
	assert_str(DayMoments.moment_at(8 * 60)["meal"]).is_equal("breakfast")
	assert_str(DayMoments.moment_at(17 * 60 + 15)["meal"]).is_equal("tea")
