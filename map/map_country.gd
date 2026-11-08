class_name MapCountry
extends Node2D
## One country on the world map: its coastline pieces, filled pale until it is
## painted and then in its own rainbow colour. Built from one entry of
## data/world_map.json.

## How far an unpainted country is washed toward white, so painted ones glow.
const UNPAINTED_WASH: float = 0.62
const OUTLINE_COLOUR: Color = Color(0.17, 0.13, 0.25, 0.55)
const OUTLINE_WIDTH: float = 3.0
const HIGHLIGHT_OUTLINE_COLOUR: Color = Color(1, 1, 1, 0.95)
const HIGHLIGHT_OUTLINE_WIDTH: float = 10.0

var country_id: String = ""
var display_name: String = ""
## A spot well inside the country: the label goes here, and so do hints.
var label_position: Vector2 = Vector2.ZERO
var rainbow_colour: Color = PaintColours.RED
var neighbour_ids: Array[String] = []
var pieces: Array[PackedVector2Array] = []
var bounds: Rect2 = Rect2()
var is_painted: bool = false:
	set(new_value):
		is_painted = new_value
		refresh_look()
var is_highlighted: bool = false:
	set(new_value):
		is_highlighted = new_value
		refresh_look()
var fills: Array[Polygon2D] = []
var outlines: Array[Line2D] = []


static func from_data(data: Dictionary) -> MapCountry:
	var country: MapCountry = MapCountry.new()
	country.name = String(data["id"])
	country.country_id = data["id"]
	country.display_name = data["name"]
	country.label_position = Vector2(data["label"][0], data["label"][1])
	country.rainbow_colour = PaintColours.RAINBOW[int(data["colour"]) % PaintColours.RAINBOW.size()]
	for neighbour_id in data["neighbours"]:
		country.neighbour_ids.append(neighbour_id)
	for raw_piece in data["polygons"]:
		var piece: PackedVector2Array = PackedVector2Array()
		for raw_point in raw_piece:
			piece.append(Vector2(raw_point[0], raw_point[1]))
		country.pieces.append(piece)
	country.build_shapes()
	return country


func build_shapes() -> void:
	for piece_index in pieces.size():
		var piece: PackedVector2Array = pieces[piece_index]
		var piece_bounds: Rect2 = Rect2(piece[0], Vector2.ZERO)
		for point in piece:
			piece_bounds = piece_bounds.expand(point)
		bounds = piece_bounds if piece_index == 0 else bounds.merge(piece_bounds)
		var fill: Polygon2D = Polygon2D.new()
		fill.polygon = piece
		add_child(fill)
		fills.append(fill)
		var outline: Line2D = Line2D.new()
		outline.points = piece
		outline.closed = true
		outline.joint_mode = Line2D.LINE_JOINT_ROUND
		outline.antialiased = true
		add_child(outline)
		outlines.append(outline)
	refresh_look()


func contains(point: Vector2) -> bool:
	if not bounds.has_point(point):
		return false
	for piece in pieces:
		if Geometry2D.is_point_in_polygon(point, piece):
			return true
	return false


func fill_colour() -> Color:
	return rainbow_colour if is_painted else rainbow_colour.lerp(Color.WHITE, UNPAINTED_WASH)


func refresh_look() -> void:
	var outline_colour: Color = HIGHLIGHT_OUTLINE_COLOUR if is_highlighted else OUTLINE_COLOUR
	var outline_width: float = HIGHLIGHT_OUTLINE_WIDTH if is_highlighted else OUTLINE_WIDTH
	for fill in fills:
		fill.color = fill_colour()
	for outline in outlines:
		outline.default_color = outline_colour
		outline.width = outline_width
