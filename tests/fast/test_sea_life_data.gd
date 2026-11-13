extends GdUnitTestSuite
# Sea life lanes and spots: every point along every lane, and every spot, is at least LAND_CLEARANCE from
# land (plain land included, and the strip under Antarctica counts as land) and not on a continent name.

const SeaLife = preload("res://map/sea_life_data.gd")

var land := []
var name_boxes := []

func before() -> void:
	var world := MapData.world()
	land.append_array(MapData.polygons_from(world["world_land"]))
	for country in world["countries"]:
		land.append_array(MapData.polygons_from(country["world"]["polygons"]))
	for continent in world["continents"]:
		var width: float = continent["name"].length() * 26.0
		name_boxes.append(Rect2(continent["label"][0] - width / 2.0, continent["label"][1] - 30, width, 60))

func test_twelve_boats_of_three_kinds() -> void:
	assert_int(SeaLife.LANES.size()).is_equal(12)
	var kinds := {}
	for lane in SeaLife.LANES:
		kinds[lane["kind"]] = true
	assert_int(kinds.size()).is_equal(3)

func test_every_lane_is_clear_of_land_and_names() -> void:
	var bad := []
	for index in SeaLife.LANES.size():
		var lane: Dictionary = SeaLife.LANES[index]
		var nearest := INF
		var on_name := false
		for step in 21:
			var point: Vector2 = lane["from"].lerp(lane["to"], step / 20.0)
			nearest = minf(nearest, _distance_to_land(point))
			on_name = on_name or _on_a_name(point)
		if nearest < SeaLife.LAND_CLEARANCE or on_name:
			bad.append("lane %d %s->%s (%.0f from land, on a name: %s)" % [index, lane["from"], lane["to"], nearest, on_name])
	assert_array(bad).is_empty()

func test_every_spot_is_clear_of_land_names_and_lanes() -> void:
	var bad := []
	for spot in SeaLife.SPOTS:
		var nearest := _distance_to_land(spot)
		if nearest < SeaLife.LAND_CLEARANCE or _on_a_name(spot):
			bad.append("spot %s is %.0f from land or on a name" % [spot, nearest])
		var nearest_lane := INF
		for lane in SeaLife.LANES:
			nearest_lane = minf(nearest_lane, spot.distance_to(Geometry2D.get_closest_point_to_segment(spot, lane["from"], lane["to"])))
		if nearest_lane < SeaLife.LANE_CLEARANCE:
			bad.append("spot %s is %.0f from a boat's lane" % [spot, nearest_lane])
	assert_array(bad).is_empty()

func _distance_to_land(point: Vector2) -> float:
	if point.y > MapData.WORLD_OFFSET_Y + 175.0 * MapData.WORLD_PIXELS_PER_DEGREE - 70.0:
		return -1.0
	var best := INF
	for piece in land:
		if Geometry2D.is_point_in_polygon(point, piece):
			return -1.0
		for i in piece.size():
			var closest := Geometry2D.get_closest_point_to_segment(point, piece[i], piece[(i + 1) % piece.size()])
			best = minf(best, point.distance_to(closest))
	return best

func _on_a_name(point: Vector2) -> bool:
	return name_boxes.any(func(box): return box.grow(30).has_point(point))
