class_name WorldMap
extends Node2D
## The whole world: sea, plain land nobody can answer with, and the countries
## that can be found. Drawn in code from data/world_map.json (baked by
## tools/bake_world_map.py), which is already in map pixels.

const WORLD_DATA_PATH: String = "res://data/world_map.json"
const SEA_COLOUR: Color = Color(0.64, 0.85, 0.96)
const SEA_LINE_COLOUR: Color = Color(1, 1, 1, 0.35)
const SEA_LINE_SPACING: float = 200.0
const PLAIN_LAND_COLOUR: Color = Color(0.91, 0.89, 0.82)
const PLAIN_LAND_OUTLINE_COLOUR: Color = Color(0.74, 0.71, 0.62)

var map_size: Vector2 = Vector2.ZERO
var countries: Dictionary = {}
var highlighted_id: String = ""


func _ready() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_DATA_PATH))
	map_size = Vector2(world["width"], world["height"])
	add_plain_land(world["plain_land"])
	for country_data in world["countries"]:
		var country: MapCountry = MapCountry.from_data(country_data)
		add_child(country)
		countries[country.country_id] = country
	queue_redraw()


func add_plain_land(raw_pieces: Array) -> void:
	var plain_land: Node2D = Node2D.new()
	plain_land.name = "PlainLand"
	add_child(plain_land)
	for raw_piece in raw_pieces:
		var piece: PackedVector2Array = PackedVector2Array()
		for raw_point in raw_piece:
			piece.append(Vector2(raw_point[0], raw_point[1]))
		var fill: Polygon2D = Polygon2D.new()
		fill.polygon = piece
		fill.color = PLAIN_LAND_COLOUR
		plain_land.add_child(fill)
		var outline: Line2D = Line2D.new()
		outline.points = piece
		outline.closed = true
		outline.width = 2.0
		outline.default_color = PLAIN_LAND_OUTLINE_COLOUR
		plain_land.add_child(outline)


## Sea, with faint lines every so often so the map reads as a map.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), SEA_COLOUR)
	var x: float = SEA_LINE_SPACING
	while x < map_size.x:
		draw_line(Vector2(x, 0), Vector2(x, map_size.y), SEA_LINE_COLOUR, 2.0)
		x += SEA_LINE_SPACING
	var y: float = SEA_LINE_SPACING
	while y < map_size.y:
		draw_line(Vector2(0, y), Vector2(map_size.x, y), SEA_LINE_COLOUR, 2.0)
		y += SEA_LINE_SPACING


## The id of the country at this spot, or "" over the sea and plain land.
func country_at(point: Vector2) -> String:
	for country_id in countries:
		if countries[country_id].contains(point):
			return country_id
	return ""


func paint_country(country_id: String) -> void:
	if countries.has(country_id):
		countries[country_id].is_painted = true


## Rings one country in white (and brings it to the front, so the ring
## isn't hidden by a neighbour). "" rings nothing.
func set_highlight(country_id: String) -> void:
	if country_id == highlighted_id:
		return
	if countries.has(highlighted_id):
		countries[highlighted_id].is_highlighted = false
	highlighted_id = country_id
	if countries.has(country_id):
		countries[country_id].is_highlighted = true
		move_child(countries[country_id], -1)
