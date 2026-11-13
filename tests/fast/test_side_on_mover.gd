extends GdUnitTestSuite
# The side-on mover on its own: an imaginary floor at y = 0, no walls.

const STEP := 1.0 / 60.0

func test_holding_right_walks_at_walk_speed_without_jumping() -> void:
	var mover := SideOnMover.new()
	var walk := _simulate(mover, 1.0, 1.0, [], 0.0)
	assert_float(mover.velocity.x).is_equal_approx(mover.walk_speed, 0.01)
	assert_bool(walk.jumped).is_false()

func test_holding_jump_goes_higher_than_a_tap() -> void:
	var held := _simulate(SideOnMover.new(), 1.2, 0.0, [0.1], 2.0)
	var tapped := _simulate(SideOnMover.new(), 1.2, 0.0, [0.1], 0.15)
	assert_bool(held.jumped and tapped.jumped).override_failure_message("pressing jump on the floor jumps").is_true()
	assert_float(held.highest).is_less(tapped.highest - 40)
	assert_float(held.highest).override_failure_message("a held jump should clear a 120px step comfortably: %.0f" % held.highest).is_less(-170)

# Walking off a ledge at x = 0 from x = -100: at walk speed 300 that's about 0.33s in
func test_coyote_time_allows_a_late_jump_but_not_too_late() -> void:
	var mover := SideOnMover.new()
	mover.coyote_seconds = 0.25
	assert_bool(_simulate(mover, 1.5, 1.0, [0.33 + 0.2], 2.0, 0.0, -100.0).jumped) \
		.override_failure_message("jumping 0.2s after walking off the edge should still work").is_true()
	mover = SideOnMover.new()
	mover.coyote_seconds = 0.25
	assert_bool(_simulate(mover, 1.5, 1.0, [0.33 + 0.4], 2.0, 0.0, -100.0).jumped) \
		.override_failure_message("but not 0.4s after").is_false()

func test_a_jump_pressed_just_before_landing_happens_on_landing() -> void:
	var mover := SideOnMover.new()
	var bounce := _simulate(mover, 2.5, 0.0, [0.1, 0.55], 0.2)
	assert_int(bounce.presses_in_the_air).override_failure_message("the second press should be in the air").is_equal(1)
	assert_int(mover.jumps_made).is_equal(2)

func test_falling_has_a_top_speed() -> void:
	var mover := SideOnMover.new()
	for frame in 300:
		mover.step(STEP, 0.0, false, false, false)
	assert_float(mover.velocity.y).is_less_equal(mover.top_fall_speed)

func test_letting_go_mid_air_keeps_sideways_speed_but_you_can_still_turn() -> void:
	var mover := SideOnMover.new()
	mover.step(STEP, 0.0, true, true, true)
	for frame in 6:
		mover.step(STEP, 1.0, true, false, false)
	var speed_after_tap := mover.velocity.x
	for frame in 20:
		mover.step(STEP, 0.0, true, false, false)
	assert_float(speed_after_tap).is_greater(0.0)
	assert_float(mover.velocity.x).is_equal_approx(speed_after_tap, 0.01)
	for frame in 10:
		mover.step(STEP, -1.0, true, false, false)
	assert_float(mover.velocity.x).is_less(0.0)

func test_letting_go_on_the_floor_stops() -> void:
	var mover := SideOnMover.new()
	mover.velocity.x = mover.walk_speed
	for frame in 30:
		mover.step(STEP, 0.0, false, false, true)
	assert_float(mover.velocity.x).is_equal(0.0)

func test_a_standing_jump_holding_a_direction_gets_a_run_up() -> void:
	var mover := SideOnMover.new()
	mover.step(STEP, 1.0, true, true, true)
	assert_float(mover.velocity.x).is_greater_equal(mover.walk_speed * 0.6)

func test_a_standing_jump_with_no_direction_goes_straight_up() -> void:
	var mover := SideOnMover.new()
	mover.step(STEP, 0.0, true, true, true)
	assert_float(mover.velocity.x).is_equal(0.0)

func test_a_running_jump_isnt_boosted_past_walk_speed() -> void:
	var mover := SideOnMover.new()
	mover.velocity.x = mover.walk_speed
	mover.step(STEP, 1.0, true, true, true)
	assert_float(mover.velocity.x).is_less_equal(mover.walk_speed)

# The real worry: from standing at a ledge, jump then one short tap of right
func test_jump_then_a_short_tap_crosses_a_gap() -> void:
	var mover := SideOnMover.new()
	var position := Vector2.ZERO
	for frame in 180:
		var time := frame * STEP
		if frame > 0 and position.y >= 0.0 and mover.velocity.y >= 0.0:
			break
		mover.step(STEP, 1.0 if time > 0.05 and time < 0.15 else 0.0, true, frame == 0, frame == 0)
		position += mover.velocity * STEP
	assert_float(position.x).is_greater(150.0)

# A flat floor at y = 0 that ends at floor_end_x. Gives the highest point reached (most negative y),
# whether a jump happened, and how many jump presses came while in the air.
func _simulate(mover: SideOnMover, seconds: float, input_x: float, jump_presses_at: Array, jump_held_until: float,
		floor_end_x := INF, start_x := 0.0) -> Dictionary:
	var position := Vector2(start_x, 0)
	var highest := 0.0
	var jumped := false
	var presses_in_the_air := 0
	for frame in int(seconds / STEP):
		var time := frame * STEP
		var on_floor := position.y >= 0.0 and position.x <= floor_end_x and mover.velocity.y >= 0.0
		if on_floor:
			position.y = 0.0
		var pressed := jump_presses_at.any(func(press_time): return absf(time - press_time) < STEP / 2.0)
		if pressed and not on_floor:
			presses_in_the_air += 1
		mover.step(STEP, input_x, time < jump_held_until, pressed, on_floor)
		jumped = jumped or mover.jumped_this_step
		position += mover.velocity * STEP
		if on_floor and mover.velocity.y > 0.0 and position.x <= floor_end_x:
			position.y = 0.0
			mover.velocity.y = 0.0
		highest = minf(highest, position.y)
	return {"highest": highest, "jumped": jumped, "presses_in_the_air": presses_in_the_air}
