class_name MapCountry
extends Node2D
## One shape on a Map mode screen: a country (on a continent screen) or the
## part of a continent the world screen draws. Its coastline pieces are
## filled pale until it is painted, then in full colour.

## How far an unpainted country is washed toward white, so painted ones glow.
const UNPAINTED_WASH: float = 0.62
const OUTLINE_COLOUR: Color = Color(0.17, 0.13, 0.25, 0.55)
const OUTLINE_WIDTH: float = 3.0
const RING_COLOUR: Color = Color(1, 1, 1, 0.95)
const RING_WIDTH: float = 10.0
## A highlighted shape without a ring (the world screen) is lightened instead.
const HIGHLIGHT_LIGHTEN: float = 0.3

## What this shape answers to: a country id, or on the world screen a continent id.
var target_id: String = ""
var display_name: String = ""
## A spot well inside the shape: hints and the magnet pull go here.
var label_position: Vector2 = Vector2.ZERO
var rainbow_colour: Color = PaintColours.RED
var pieces: Array[PackedVector2Array] = []
var bounds: Rect2 = Rect2()
## Pale until painted. The world screen draws everything in full colour.
var washes_when_unpainted: bool = true
## Ring the outline when highlighted (a country), or lighten the fill (a continent).
var rings_when_highlighted: bool = true
var outline_colour: Color = OUTLINE_COLOUR
var outline_width: float = OUTLINE_WIDTH
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


static func make(new_target_id: String, new_display_name: String, new_pieces: Array[PackedVector2Array], new_label_position: Vector2,
		new_rainbow_colour: Color) -> MapCountry:
	var country: MapCountry = MapCountry.new()
	country.name = new_target_id
	country.target_id = new_target_id
	country.display_name = new_display_name
	country.pieces = new_pieces
	country.label_position = new_label_position
	country.rainbow_colour = new_rainbow_colour
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
	if not bounds.grow(1.0).has_point(point):
		return false
	for piece in pieces:
		if Geometry2D.is_point_in_polygon(point, piece):
			return true
	return false


func fill_colour() -> Color:
	var colour: Color = rainbow_colour
	if washes_when_unpainted and not is_painted:
		colour = rainbow_colour.lerp(Color.WHITE, UNPAINTED_WASH)
	if is_highlighted and not rings_when_highlighted:
		colour = colour.lightened(HIGHLIGHT_LIGHTEN)
	return colour


func refresh_look() -> void:
	var is_ringed: bool = is_highlighted and rings_when_highlighted
	for fill in fills:
		fill.color = fill_colour()
	for outline in outlines:
		outline.default_color = RING_COLOUR if is_ringed else outline_colour
		outline.width = RING_WIDTH if is_ringed else outline_width
