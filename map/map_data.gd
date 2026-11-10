class_name MapData
extends RefCounted
## data/world_map.json, read once: the world screen, a screen per continent,
## and every country on them (see tools/bake_world_map.py). Everything in it is
## already in 1920 x 1080 screen pixels.

const WORLD_DATA_PATH: String = "res://data/world_map.json"
const SCREEN_SIZE: Vector2 = Vector2(1920, 1080)
## How the world screen was projected, so a screen point can be turned back
## into longitude and latitude (for the globe).
const WORLD_PIXELS_PER_DEGREE: float = 1920.0 / 360.0
const WORLD_OFFSET_Y: float = (1080.0 - 175.0 * WORLD_PIXELS_PER_DEGREE) / 2.0
const WORLD_TOP_LATITUDE: float = 85.0

static var cached_world: Dictionary = {}


static func world() -> Dictionary:
	if cached_world.is_empty():
		cached_world = JSON.parse_string(FileAccess.get_file_as_string(WORLD_DATA_PATH))
	return cached_world


static func continent(continent_id: String) -> Dictionary:
	for continent_data in world()["continents"]:
		if continent_data["id"] == continent_id:
			return continent_data
	return {}


static func country(country_id: String) -> Dictionary:
	for country_data in world()["countries"]:
		if country_data["id"] == country_id:
			return country_data
	return {}


## Index 6 is the cyan of Antarctica; 0-5 are the rainbow.
static func colour_of(colour_index: int) -> Color:
	return PaintColours.CYAN if colour_index >= PaintColours.RAINBOW.size() else PaintColours.RAINBOW[colour_index]


static func polygons_from(raw_polygons: Array) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	for raw_polygon in raw_polygons:
		var polygon: PackedVector2Array = PackedVector2Array()
		for raw_point in raw_polygon:
			polygon.append(Vector2(raw_point[0], raw_point[1]))
		polygons.append(polygon)
	return polygons


## x is longitude, y is latitude, both in degrees.
static func longitude_latitude_of(world_screen_point: Vector2) -> Vector2:
	return Vector2(world_screen_point.x / WORLD_PIXELS_PER_DEGREE - 180.0,
		WORLD_TOP_LATITUDE - (world_screen_point.y - WORLD_OFFSET_Y) / WORLD_PIXELS_PER_DEGREE)
