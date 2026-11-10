class_name MapScreen
extends Node2D
## One whole 1920 x 1080 screen of Map mode: sea behind, shapes on top.
## WorldScreen and ContinentScreen fill it in.

const SEA_COLOUR: Color = Color(0.64, 0.85, 0.96)
const SEA_LINE_COLOUR: Color = Color(1, 1, 1, 0.35)
const SEA_LINE_SPACING: float = 240.0
const PLAIN_LAND_COLOUR: Color = Color(0.91, 0.89, 0.82)
const PLAIN_LAND_OUTLINE_COLOUR: Color = Color(0.74, 0.71, 0.62)

var shapes: Array[MapCountry] = []
## Where the magnet pull gathers: the middle of each shape.
var magnets: Array = []
var highlighted_target: String = ""


## Sea, with faint lines every so often so the screen reads as a map.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MapData.SCREEN_SIZE), SEA_COLOUR)
	var x: float = SEA_LINE_SPACING
	while x < MapData.SCREEN_SIZE.x:
		draw_line(Vector2(x, 0), Vector2(x, MapData.SCREEN_SIZE.y), SEA_LINE_COLOUR, 2.0)
		x += SEA_LINE_SPACING
	var y: float = SEA_LINE_SPACING
	while y < MapData.SCREEN_SIZE.y:
		draw_line(Vector2(0, y), Vector2(MapData.SCREEN_SIZE.x, y), SEA_LINE_COLOUR, 2.0)
		y += SEA_LINE_SPACING


## Land nobody can answer with, drawn under the shapes.
func add_plain_land(raw_pieces: Array) -> void:
	var plain_land: Node2D = Node2D.new()
	plain_land.name = "PlainLand"
	add_child(plain_land)
	for piece in MapData.polygons_from(raw_pieces):
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


func add_shape(shape: MapCountry) -> void:
	add_child(shape)
	shapes.append(shape)


## The id of the shape at this spot, or "" over the sea and plain land.
func target_at(point: Vector2) -> String:
	for shape in shapes:
		if shape.contains(point):
			return shape.target_id
	return ""


func name_of(target: String) -> String:
	for shape in shapes:
		if shape.target_id == target:
			return shape.display_name
	return ""


## Rings (or lightens) every shape of one target. "" clears it.
func set_highlight(target: String) -> void:
	if target == highlighted_target:
		return
	highlighted_target = target
	for shape in shapes:
		shape.is_highlighted = shape.target_id == target and target != ""
		# Only a ringed country needs raising, so its ring isn't hidden by a neighbour. A
		# continent on the world screen mustn't climb over the names laid on top.
		if shape.is_highlighted and shape.rings_when_highlighted:
			move_child(shape, -1)
