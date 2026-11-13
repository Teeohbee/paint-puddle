extends GdUnitTestSuite
# The spring that squashes and stretches a blob when it lands or jumps.

func test_a_fresh_spring_is_at_rest() -> void:
	assert_vector(SquashStretchSpring.new().scale).is_equal(Vector2.ONE)

func test_a_kick_stretches_wobbles_past_rest_then_settles() -> void:
	var spring := SquashStretchSpring.new()
	spring.kick(Vector2(2.0, -2.0))
	var largest_stretch := 1.0
	var went_below_rest := false
	for frame in 30:
		spring.step(1.0 / 60.0)
		largest_stretch = maxf(largest_stretch, spring.scale.x)
		went_below_rest = went_below_rest or spring.scale.x < 1.0
	assert_float(largest_stretch).is_greater(1.05)
	assert_bool(went_below_rest).override_failure_message("it should wobble back past rest").is_true()
	for frame in 120:
		spring.step(1.0 / 60.0)
	assert_float(spring.scale.distance_to(Vector2.ONE)).override_failure_message(
		"it should settle within 2.5s, is at %s" % spring.scale).is_less(0.01)
