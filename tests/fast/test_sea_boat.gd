extends GdUnitTestSuite
# Sea boats: sail along their lane, turn round at each end, face the way they go, bob, and every shape fills.

const Boat = preload("res://map/sea_boat.gd")
const Art = preload("res://map/sea_art.gd")
const SeaLife = preload("res://map/sea_life_data.gd")

func test_every_boat_shape_fills() -> void:
	for path in [Boat.SAILING_HULL, Boat.SAILING_MAIN_SAIL, Boat.SAILING_FRONT_SAIL, Boat.CARGO_HULL, Boat.DINGHY_HULL, Boat.DINGHY_SAIL]:
		var outline: PackedVector2Array = Art.outline_of(path)
		assert_bool(outline.size() >= 3 and not Geometry2D.triangulate_polygon(outline).is_empty()) \
			.override_failure_message("shape doesn't fill: %s" % path.left(20)).is_true()

func test_a_closing_point_repeating_the_first_is_dropped() -> void:
	assert_int(Art.outline_of("M-40 0 L40 0 L0 20 L-40 0Z").size()).is_equal(3)

func test_a_boat_sails_bobs_and_turns_at_each_end() -> void:
	var lane := {"kind": SeaLife.Kind.CARGO_SHIP, "from": Vector2(100, 500), "to": Vector2(400, 500),
		"hull": Color.RED, "sail": Color.BLUE, "sail_2": Color.GREEN}
	var boat: Node2D = Boat.make(lane, 15.0, 0.0, 1.0, 0.0)
	add_child(boat)
	auto_free(boat)
	assert_float(boat.facing).override_failure_message("should start facing the lane's end").is_equal(1.0)
	assert_float(boat.scale.x).is_greater(0.0)
	var start_x := boat.position.x
	var lowest := INF
	var highest := -INF
	for i in 60:
		boat._process(1.0 / 60.0)
		lowest = minf(lowest, boat.position.y)
		highest = maxf(highest, boat.position.y)
	assert_float(boat.position.x - start_x).override_failure_message("should move 15px in a second").is_equal_approx(15.0, 0.001)
	assert_float(highest - lowest).is_between(1.0, 2.0 * Boat.BOB_HEIGHT + 0.01)
	var turned_at := -1.0
	var smallest_width := INF
	for i in 60 * 30:
		boat._process(1.0 / 60.0)
		smallest_width = minf(smallest_width, absf(boat.scale.x))
		if turned_at < 0 and boat.heading < 0:
			turned_at = boat.position.x
	assert_float(turned_at).override_failure_message("should turn round at the lane's end").is_between(399.0, 400.0)
	assert_float(boat.facing).override_failure_message("should face left going back").is_equal(-1.0)
	assert_float(boat.scale.x).is_less(0.0)
	assert_float(smallest_width).override_failure_message("squashed flat while turning").is_greater(0.0)
	var far_left := INF
	for i in 60 * 12:
		boat._process(1.0 / 60.0)
		far_left = minf(far_left, boat.position.x)
	assert_float(far_left).override_failure_message("should turn again at the lane's start").is_greater_equal(100.0 - 0.01)
	assert_float(boat.heading).is_greater(0.0)

func test_a_lane_drawn_leftwards_starts_facing_left() -> void:
	var boat: Node2D = auto_free(Boat.make({"kind": SeaLife.Kind.DINGHY, "from": Vector2(400, 500), "to": Vector2(100, 520),
		"hull": Color.RED, "sail": Color.WHITE}, 12.0, 0.5, 1.0, 1.0))
	assert_float(boat.facing).is_equal(-1.0)
	assert_that(boat.sail_2_colour).override_failure_message("a dinghy's one sail is fine").is_equal(Color.WHITE)
