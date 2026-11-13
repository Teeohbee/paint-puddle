extends GdUnitTestSuite
# data/world_map.json is baked by tools/bake_world_map.py. The game trusts it, so this checks the promises
# Map mode leans on: every country can be landed on in every screen it's shown on, every outline fills
# cleanly, neighbours agree, neighbours never share a colour, and straddlers show twice.

var world: Dictionary
var by_id := {}
var continents := {}

func before() -> void:
	world = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	for country in world["countries"]:
		by_id[country["id"]] = country
	for continent in world["continents"]:
		continents[continent["id"]] = continent

func test_the_world_has_its_basic_shape() -> void:
	assert_array([int(world["screen"][0]), int(world["screen"][1])]).is_equal([1920, 1080])
	assert_int(world["countries"].size()).is_between(196, 214)
	assert_int(by_id.size()).override_failure_message("country ids repeat").is_equal(world["countries"].size())
	assert_int(continents.size()).is_equal(7)

func test_every_country_colour_is_one_of_six() -> void:
	var bad: Array = world["countries"].filter(func(c): return int(c["colour"]) < 0 or int(c["colour"]) >= 6).map(func(c): return c["id"])
	assert_array(bad).is_empty()

func test_every_outline_fills_and_every_label_is_inside_and_on_screen() -> void:
	var unfillable := []
	var lost_labels := []
	var missing_views := []
	var off_screen := []
	for country in world["countries"]:
		var id: String = country["id"]
		for raw in country["world"]["polygons"]:
			if not _fills_cleanly(raw):
				unfillable.append("%s (world)" % id)
		if not _label_is_inside(country["world"]["polygons"], country["world"]["label"]):
			lost_labels.append("%s (world)" % id)
		for continent_id in country["continents"]:
			if not continents[continent_id]["zoomable"]:
				continue
			if not country["views"].has(continent_id):
				missing_views.append("%s in %s" % [id, continent_id])
				continue
			var view: Dictionary = country["views"][continent_id]
			for raw in view["polygons"]:
				if not _fills_cleanly(raw):
					unfillable.append("%s (%s)" % [id, continent_id])
			if not _label_is_inside(view["polygons"], view["label"]):
				lost_labels.append("%s (%s)" % [id, continent_id])
			var label: Array = view["label"]
			if label[0] < 0 or label[0] > 1920 or label[1] < 0 or label[1] > 1080:
				off_screen.append("%s (%s)" % [id, continent_id])
	assert_array(unfillable).override_failure_message("outlines that don't fill: %s" % [unfillable]).is_empty()
	assert_array(lost_labels).override_failure_message("labels outside their country: %s" % [lost_labels]).is_empty()
	assert_array(missing_views).override_failure_message("missing from a continent screen: %s" % [missing_views]).is_empty()
	assert_array(off_screen).override_failure_message("labels off screen: %s" % [off_screen]).is_empty()

func test_neighbours_agree_and_never_share_a_colour() -> void:
	var bad := []
	for country in world["countries"]:
		for neighbour in country["neighbours"]:
			if not (by_id.has(neighbour) and by_id[neighbour]["neighbours"].has(country["id"])):
				bad.append("%s and %s disagree about being neighbours" % [country["id"], neighbour])
			elif by_id[neighbour]["colour"] == country["colour"]:
				bad.append("%s and %s share a colour" % [country["id"], neighbour])
	assert_array(bad).is_empty()

func test_enough_countries_can_be_asked_for_on_each_continent() -> void:
	var playable := {}
	for country in world["countries"]:
		if country["playable"]:
			playable[country["home"]] = playable.get(country["home"], 0) + 1
	assert_int(playable.values().reduce(func(a, b): return a + b, 0)).is_greater(100)
	for continent_id in ["europe", "asia", "africa", "south_america"]:
		assert_int(playable.get(continent_id, 0)).override_failure_message("%s has %d playable countries, wants 10+" %
			[continent_id, playable.get(continent_id, 0)]).is_greater_equal(10)
	assert_int(playable.get("north_america", 0)).is_greater_equal(5)
	assert_int(playable.get("oceania", 0)).is_greater_equal(3)

# Straddlers are on both screens, home first
func test_straddlers_show_on_both_screens(id: String, homes: Array, test_parameters := [
	["russia", ["europe", "asia"]],
	["turkey", ["asia", "europe"]],
	["egypt", ["africa", "asia"]],
]) -> void:
	assert_array(by_id[id]["continents"]).is_equal(homes)
	for continent_id in homes:
		assert_bool(by_id[id]["views"].has(continent_id)).override_failure_message("%s has no shape on %s" % [id, continent_id]).is_true()

func test_the_world_screen_knows_where_to_split_russia() -> void:
	assert_bool(world["world_split"].has("russia")).is_true()

# Overseas pieces were cut: France's label is in Europe, the USA's on the mainland
func test_overseas_pieces_dont_pull_labels_away() -> void:
	var france: Array = by_id["france"]["views"]["europe"]["label"]
	assert_bool(france[0] > 600 and france[0] < 1000 and france[1] > 600 and france[1] < 950) \
		.override_failure_message("France's label is at %s, not in Europe" % [france]).is_true()
	var usa: Array = by_id["usa"]["views"]["north_america"]["label"]
	assert_bool(usa[0] > 300 and usa[0] < 1200 and usa[1] > 400) \
		.override_failure_message("the USA label is at %s, not on the mainland" % [usa]).is_true()

func test_antarctica_is_asked_for_on_the_world_screen_only() -> void:
	assert_bool(by_id["antarctica"]["playable"]).is_true()
	assert_dict(by_id["antarctica"]["views"]).is_empty()

func _polygon_of(raw: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for pair in raw:
		points.append(Vector2(pair[0], pair[1]))
	return points

func _fills_cleanly(raw: Array) -> bool:
	return not Geometry2D.triangulate_polygon(_polygon_of(raw)).is_empty()

func _label_is_inside(polygons: Array, label: Array) -> bool:
	return polygons.any(func(raw): return Geometry2D.is_point_in_polygon(Vector2(label[0], label[1]), _polygon_of(raw)))
