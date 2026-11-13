extends GdUnitTestSuite
# How a blob speeds up, slows down and turns when steered top-down.

var mover: TopDownMover

func before_test() -> void:
	mover = TopDownMover.new()

func test_holding_right_reaches_top_speed() -> void:
	assert_float(_run(Vector2.ZERO, Vector2.RIGHT, 1.0).length()).is_equal_approx(mover.top_speed, 0.01)

# A D-pad diagonal arrives as (1, 1), which must not be faster
func test_dpad_diagonals_are_no_faster() -> void:
	assert_float(_run(Vector2.ZERO, Vector2(1, 1), 1.0).length()).is_equal_approx(mover.top_speed, 0.01)

func test_it_gets_going_quickly() -> void:
	assert_float(_run(Vector2.ZERO, Vector2.RIGHT, 0.25).length()).is_greater_equal(mover.top_speed * 0.95)

func test_letting_go_stops_within_a_fifth_of_a_second() -> void:
	var full_speed := _run(Vector2.ZERO, Vector2.RIGHT, 1.0)
	assert_vector(_run(full_speed, Vector2.ZERO, 0.2)).is_equal(Vector2.ZERO)

func test_turning_round_is_snappy() -> void:
	var full_speed := _run(Vector2.ZERO, Vector2.RIGHT, 1.0)
	assert_float(_run(full_speed, Vector2.LEFT, 0.3).x).is_less(-mover.top_speed * 0.5)

func test_a_gentle_stick_push_goes_gently() -> void:
	assert_float(_run(Vector2.ZERO, Vector2(0.5, 0), 1.0).length()).is_equal_approx(mover.top_speed * 0.5, 0.01)

func _run(velocity: Vector2, input_vector: Vector2, seconds: float) -> Vector2:
	for frame in int(seconds * 60):
		velocity = mover.next_velocity(velocity, input_vector, 1.0 / 60.0)
	return velocity
