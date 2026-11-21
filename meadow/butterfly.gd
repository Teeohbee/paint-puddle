class_name Butterfly
extends Node2D
## A butterfly carrying a letter stone in Meadow Medium: four rounded wings in
## the stone's colour, spread behind it and flapping, with a body and antennae
## peeping over the top. From the steering prototype, wings a quarter smaller.

const WING_SCALE: float = 0.75

var colour: Color = PaintColours.PURPLE
var flap_time: float = randf() * TAU


func _ready() -> void:
	show_behind_parent = true


func _process(delta: float) -> void:
	flap_time += delta
	queue_redraw()


func _draw() -> void:
	# Open and close, never quite shut, so it always reads as a butterfly
	var open: float = 0.35 + 0.65 * absf(sin(flap_time * 9.0))
	var edge: Color = colour.darkened(0.35)
	for side in [-1.0, 1.0]:
		draw_wing(Vector2(side * 40.0, -30.0), Vector2(side * 46.0 * open, -40.0), 38.0, edge)
		draw_wing(Vector2(side * 30.0, 20.0), Vector2(side * 34.0 * open, 26.0), 28.0, edge)
	draw_set_transform(Vector2(0, -6), 0.0, Vector2(0.45, 1.0))
	draw_circle(Vector2.ZERO, 40.0, PaintColours.INK.lightened(0.15))
	draw_set_transform(Vector2.ZERO)
	for side in [-1.0, 1.0]:
		var tip: Vector2 = Vector2(side * 22.0, -78.0)
		draw_polyline(PackedVector2Array([Vector2(side * 4.0, -40.0), Vector2(side * 10.0, -62.0), tip]), PaintColours.INK, 3.0, true)
		draw_circle(tip, 5.0, PaintColours.INK)


## One wing: a rounded shape stretched out sideways as it opens, with a spot.
## Scaled about its root, so smaller wings still meet the body.
func draw_wing(root: Vector2, reach: Vector2, radius: float, edge: Color) -> void:
	radius *= WING_SCALE
	reach *= WING_SCALE
	var centre: Vector2 = root + Vector2(reach.x * 0.5, reach.y * 0.35)
	var stretch: Vector2 = Vector2(maxf(absf(reach.x) / radius, 0.35), 1.0)
	draw_set_transform(centre, 0.0, stretch)
	draw_circle(Vector2.ZERO, radius + 4.0, edge)
	draw_circle(Vector2.ZERO, radius, colour.lightened(0.25))
	draw_circle(Vector2(0, -radius * 0.15), radius * 0.38, Color.WHITE.lerp(colour, 0.3))
	draw_set_transform(Vector2.ZERO)
