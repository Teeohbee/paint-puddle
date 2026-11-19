extends GdUnitTestSuite
# ClockWinder: turns left/right on the D-pad into steps. One press is one step; holding waits 0.35 s,
# then repeats, starting 0.18 s apart and 18% quicker each time, never faster than 0.025 s apart.

const FRAME: float = 1.0 / 60.0

## Holds a direction for a while, a frame at a time, and adds up the steps.
func steps_while_holding(winder: ClockWinder, direction: int, seconds: float) -> int:
	var total_steps: int = 0
	var frames: int = roundi(seconds / FRAME)
	for frame in frames:
		total_steps += winder.update(direction, FRAME)
	return total_steps

func test_a_press_winds_one_step_straight_away() -> void:
	var winder := ClockWinder.new()
	assert_int(winder.update(1, FRAME)).is_equal(1)
	assert_int(ClockWinder.new().update(-1, FRAME)).is_equal(-1)

func test_nothing_held_winds_nothing() -> void:
	assert_int(steps_while_holding(ClockWinder.new(), 0, 2.0)).is_equal(0)

func test_a_short_hold_is_still_one_step() -> void:
	assert_int(steps_while_holding(ClockWinder.new(), 1, 0.3)).is_equal(1)

func test_holding_starts_repeating_after_the_first_delay() -> void:
	var winder := ClockWinder.new()
	assert_int(steps_while_holding(winder, 1, 0.34)).is_equal(1)
	assert_int(steps_while_holding(winder, 1, 0.05)).is_equal(1)

func test_each_repeat_comes_quicker() -> void:
	var winder := ClockWinder.new()
	var seconds_at_each_step: Array[float] = []
	for frame in 120:
		if winder.update(1, FRAME) != 0:
			seconds_at_each_step.append(frame * FRAME)
	assert_float(seconds_at_each_step[1] - seconds_at_each_step[0]).is_equal_approx(0.35, 0.02)
	assert_float(seconds_at_each_step[2] - seconds_at_each_step[1]).is_equal_approx(0.18, 0.02)
	assert_float(seconds_at_each_step[4] - seconds_at_each_step[3]).is_less(seconds_at_each_step[2] - seconds_at_each_step[1])

func test_a_long_hold_tops_out_at_about_40_steps_a_second() -> void:
	var winder := ClockWinder.new()
	steps_while_holding(winder, 1, 3.0)
	var steps_in_the_next_second: int = steps_while_holding(winder, 1, 1.0)
	assert_int(steps_in_the_next_second).is_between(38, 41)

func test_letting_go_stops_straight_away_and_the_next_press_is_one_step_again() -> void:
	var winder := ClockWinder.new()
	steps_while_holding(winder, 1, 2.0)
	assert_int(steps_while_holding(winder, 0, 0.5)).is_equal(0)
	assert_int(winder.update(1, FRAME)).is_equal(1)
	assert_int(steps_while_holding(winder, 1, 0.3)).is_equal(0)

func test_turning_round_winds_the_other_way_straight_away() -> void:
	var winder := ClockWinder.new()
	steps_while_holding(winder, 1, 2.0)
	assert_int(winder.update(-1, FRAME)).is_equal(-1)
	assert_int(steps_while_holding(winder, -1, 0.3)).is_equal(0)
