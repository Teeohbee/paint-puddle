class_name SplatBall
extends Node2D
## A ball of paint in flight. It rises and falls in an arc while its shadow
## slides along the ground, and `position` is the spot on the ground below it.

const FLIGHT_SECONDS: float = 0.45
const ARC_HEIGHT: float = 90.0
const LIFT: float = 40.0
const RADIUS: float = 26.0

var thrower: PaintPlayer
var paint_bits: int = 0
var paint_colour: Color = Color.WHITE
var start_position: Vector2
var landing_position: Vector2
var age: float = 0.0


## 0 as it leaves the blob, 1 as it lands.
func progress() -> float:
	return clampf(age / FLIGHT_SECONDS, 0.0, 1.0)


func has_landed() -> bool:
	return age >= FLIGHT_SECONDS


func advance(delta: float) -> void:
	age += delta
	position = start_position.lerp(landing_position, progress())
	queue_redraw()


func _draw() -> void:
	var height: float = sin(PI * progress()) * ARC_HEIGHT
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, RADIUS, Color(PaintColours.INK, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var ball_centre: Vector2 = Vector2(0, -LIFT - height)
	draw_circle(ball_centre, RADIUS + 3.0, Color(PaintColours.INK, 0.5))
	draw_circle(ball_centre, RADIUS, paint_colour)
	draw_circle(ball_centre + Vector2(-8, -8), 7.0, Color(1, 1, 1, 0.5))
