class_name PaintCanvas
extends Node2D
## The picture in paint mode. Paint is drawn into a texture that is never
## cleared, so a long painting costs no more than a short one. Wiping fades
## the picture away and starts a fresh one.

const PICTURE_SIZE: Vector2i = Vector2i(1920, 1080)
const DAB_RADIUS: float = 30.0
const DAB_SPACING: float = 6.0

var dabs_painted: int = 0
var last_colour: Color = Color.TRANSPARENT
var picture: SubViewport
var picture_sprite: Sprite2D
var brush: Node2D
var waiting_dabs: Array[Dictionary] = []
var wipe_tween: Tween


func _ready() -> void:
	picture = SubViewport.new()
	picture.size = PICTURE_SIZE
	picture.transparent_bg = true
	picture.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	picture.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	add_child(picture)
	brush = Node2D.new()
	brush.draw.connect(draw_waiting_dabs)
	picture.add_child(brush)
	picture_sprite = Sprite2D.new()
	picture_sprite.centered = false
	picture_sprite.texture = picture.get_texture()
	add_child(picture_sprite)


## Paints a smooth line of round dabs from one point to another.
func paint_line(from: Vector2, to: Vector2, colour: Color) -> void:
	var points: PackedVector2Array = dab_points(from, to, DAB_SPACING)
	for point in points:
		waiting_dabs.append({"position": point, "colour": colour})
	dabs_painted += points.size()
	last_colour = colour
	brush.queue_redraw()


## Points from just after `from` up to and including `to`, never further
## apart than `spacing`.
static func dab_points(from: Vector2, to: Vector2, spacing: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = maxi(1, ceili(from.distance_to(to) / spacing))
	for step in range(1, steps + 1):
		points.append(from.lerp(to, float(step) / steps))
	return points


func draw_waiting_dabs() -> void:
	for dab in waiting_dabs:
		brush.draw_circle(dab.position, DAB_RADIUS, dab.colour)
	waiting_dabs.clear()


## Fades the picture out, then starts a clean one.
func wipe() -> void:
	dabs_painted = 0
	waiting_dabs.clear()
	if wipe_tween != null:
		wipe_tween.kill()
	wipe_tween = create_tween()
	wipe_tween.tween_property(picture_sprite, "modulate:a", 0.0, 0.5)
	wipe_tween.tween_callback(func(): picture.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE)
	wipe_tween.tween_interval(0.05)
	wipe_tween.tween_property(picture_sprite, "modulate:a", 1.0, 0.0)
