class_name PaintBlobLook
extends Node2D
## Draws the paint blob: a soft wobbling body, a shine, big eyes that look
## where it's going, a smile and a shadow. No textures - it's all _draw().

const BODY_RADIUS: float = 44.0
const BODY_POINT_COUNT: int = 40
const EYE_SPACING: float = 15.0
const EYE_RADIUS: float = 11.0
const PUPIL_RADIUS: float = 6.0

@export var paint_colour: Color = Color(1.0, 0.36, 0.43):
	set(new_colour):
		paint_colour = new_colour
		queue_redraw()

## Which way the eyes look, and which way the squash-stretch points.
var look_direction: Vector2 = Vector2.DOWN
var squash_stretch: SquashStretchSpring = SquashStretchSpring.new()

var wobble_time: float = 0.0
var seconds_until_next_blink: float = 2.0
var blink_seconds_left: float = 0.0


func _process(delta: float) -> void:
	wobble_time += delta
	squash_stretch.step(delta)
	update_blink(delta)
	queue_redraw()


func update_blink(delta: float) -> void:
	if blink_seconds_left > 0.0:
		blink_seconds_left -= delta
		return
	seconds_until_next_blink -= delta
	if seconds_until_next_blink <= 0.0:
		blink_seconds_left = 0.12
		seconds_until_next_blink = randf_range(2.0, 5.0)


func _draw() -> void:
	draw_shadow()
	var stretch_angle: float = look_direction.angle()
	# The squash-stretch runs along the direction of travel
	draw_set_transform(Vector2.ZERO, stretch_angle, squash_stretch.scale)
	draw_colored_polygon(body_outline_points(BODY_RADIUS + 4.0, -stretch_angle), paint_colour.darkened(0.35))
	draw_colored_polygon(body_outline_points(BODY_RADIUS, -stretch_angle), paint_colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_shine()
	draw_face()


func draw_shadow() -> void:
	draw_set_transform(Vector2(0, BODY_RADIUS * 0.75), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, BODY_RADIUS * 0.95, Color(0.1, 0.2, 0.05, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The wobble is worked out in the blob's own upright frame, so turning
## doesn't make the lumps spin round the edge.
func body_outline_points(radius: float, upright_angle_offset: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in BODY_POINT_COUNT:
		var angle: float = TAU * point_index / BODY_POINT_COUNT
		var upright_angle: float = angle - upright_angle_offset
		var wobble: float = 0.035 * sin(3.0 * upright_angle + wobble_time * 3.1) \
			+ 0.025 * sin(5.0 * upright_angle - wobble_time * 2.3)
		points.append(Vector2.from_angle(angle) * radius * (1.0 + wobble))
	return points


func draw_shine() -> void:
	var shine_centre: Vector2 = Vector2(-BODY_RADIUS * 0.42, -BODY_RADIUS * 0.45)
	draw_set_transform(shine_centre, -0.6, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, BODY_RADIUS * 0.26, Color(1, 1, 1, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_face() -> void:
	var face_offset: Vector2 = look_direction.limit_length(1.0) * 7.0
	var is_blinking: bool = blink_seconds_left > 0.0
	for side in [-1.0, 1.0]:
		var eye_centre: Vector2 = Vector2(side * EYE_SPACING, -6.0) + face_offset
		if is_blinking:
			draw_line(eye_centre - Vector2(EYE_RADIUS * 0.8, 0), eye_centre + Vector2(EYE_RADIUS * 0.8, 0),
				Color(0.17, 0.13, 0.25), 3.0, true)
			continue
		draw_circle(eye_centre, EYE_RADIUS, Color.WHITE)
		var pupil_centre: Vector2 = eye_centre + look_direction.limit_length(1.0) * 3.5
		draw_circle(pupil_centre, PUPIL_RADIUS, Color(0.17, 0.13, 0.25))
		draw_circle(pupil_centre + Vector2(-2, -2), 2.0, Color.WHITE)
	var mouth_centre: Vector2 = Vector2(0, 10) + face_offset
	draw_arc(mouth_centre, 7.0, 0.35, PI - 0.35, 12, Color(0.17, 0.13, 0.25), 3.0, true)
