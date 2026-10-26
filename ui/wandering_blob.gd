class_name WanderingBlob
extends Node2D
## A blob that potters about on its own behind the menus.

const SPEED: float = 130.0

var wander_area: Rect2 = Rect2(160, 160, 1600, 760)
var target: Vector2
var seconds_resting: float = 0.0
var look: PaintBlobLook


func _ready() -> void:
	look = PaintBlobLook.new()
	add_child(look)
	pick_new_target()


func set_paint_colour(colour: Color) -> void:
	look.paint_colour = colour


func pick_new_target() -> void:
	target = Vector2(randf_range(wander_area.position.x, wander_area.end.x), randf_range(wander_area.position.y, wander_area.end.y))


func _process(delta: float) -> void:
	if seconds_resting > 0.0:
		seconds_resting -= delta
		if seconds_resting <= 0.0:
			look.squash_stretch.kick(Vector2(6, -5))
		return
	var to_target: Vector2 = target - position
	if to_target.length() < 8.0:
		seconds_resting = randf_range(0.8, 2.5)
		look.squash_stretch.kick(Vector2(-5, 4))
		pick_new_target()
		return
	position += to_target.normalized() * minf(SPEED * delta, to_target.length())
	look.look_direction = look.look_direction.lerp(to_target.normalized(), 6.0 * delta).normalized()
