class_name HintArrow
extends Node2D
## A soft, see-through arrow beside the pin that points the way to what the
## task is asking for. It turns smoothly, fades away as the pin gets close,
## and only shows when the runner wants it (after a few wrong tries, or a
## while with no luck).

const DISTANCE_FROM_TIP: float = 95.0
const LENGTH: float = 120.0
const SHAFT_WIDTH: float = 22.0
const HEAD_WIDTH: float = 62.0
const HEAD_LENGTH: float = 56.0
const FILL_COLOUR: Color = Color(1, 1, 1, 0.62)
const OUTLINE_COLOUR: Color = Color(0.17, 0.13, 0.25, 0.4)
## Closer than this to the target and the arrow has done its job.
const GONE_WITHIN: float = 130.0
const FULL_BEYOND: float = 330.0
const FADE_SPEED: float = 3.0
const TURN_SPEED: float = 8.0

## The pin's tip, and where the arrow points. Set by the runner every frame.
var origin: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var is_wanted: bool = false
var opacity: float = 0.0
var angle: float = 0.0


## 1 far from the target, 0 once the pin is right by it.
static func proximity_fade(distance_to_target: float) -> float:
	return clampf((distance_to_target - GONE_WITHIN) / (FULL_BEYOND - GONE_WITHIN), 0.0, 1.0)


## Halfway along the arrow, where it is drawn.
func middle() -> Vector2:
	return origin + Vector2.from_angle(angle) * (DISTANCE_FROM_TIP + LENGTH / 2.0)


func _process(delta: float) -> void:
	var wanted_opacity: float = proximity_fade(origin.distance_to(target)) if is_wanted else 0.0
	opacity = move_toward(opacity, wanted_opacity, FADE_SPEED * delta)
	angle = lerp_angle(angle, origin.direction_to(target).angle(), clampf(TURN_SPEED * delta, 0.0, 1.0))
	visible = opacity > 0.01
	queue_redraw()


func _draw() -> void:
	if opacity <= 0.01:
		return
	var along: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = along.orthogonal()
	var start: Vector2 = origin + along * DISTANCE_FROM_TIP
	var tip: Vector2 = start + along * LENGTH
	var neck: Vector2 = tip - along * HEAD_LENGTH
	var outline: PackedVector2Array = PackedVector2Array([
		start + across * SHAFT_WIDTH / 2.0, neck + across * SHAFT_WIDTH / 2.0, neck + across * HEAD_WIDTH / 2.0, tip,
		neck - across * HEAD_WIDTH / 2.0, neck - across * SHAFT_WIDTH / 2.0, start - across * SHAFT_WIDTH / 2.0])
	draw_colored_polygon(outline, Color(FILL_COLOUR, FILL_COLOUR.a * opacity))
	draw_polyline(outline + PackedVector2Array([outline[0]]), Color(OUTLINE_COLOUR, OUTLINE_COLOUR.a * opacity), 3.0, true)
