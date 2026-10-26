class_name MeadowBlob
extends CharacterBody2D
## The paint blob seen from above. Drives with the D-pad or stick, slides
## along hedges and bushes, and squashes when it starts, stops or bumps.

signal bumped_into_something

var mover: TopDownMover = TopDownMover.new()
var was_moving: bool = false
## Which paint the blob is wearing - see PaintMixing.
var paint_name: String = "clean"
var colour_tween: Tween

@onready var look: PaintBlobLook = $Look


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	look.paint_colour = PaintMixing.colour_of(paint_name)


## Changes the blob's paint with a quick blend and a big wobble.
func change_paint(new_paint_name: String) -> void:
	paint_name = new_paint_name
	if colour_tween != null:
		colour_tween.kill()
	colour_tween = create_tween()
	colour_tween.tween_property(look, "paint_colour", PaintMixing.colour_of(new_paint_name), 0.3)
	look.squash_stretch.kick(Vector2(-12, 12))


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = mover.next_velocity(velocity, input_direction, delta)
	var speed_before_moving: float = velocity.length()
	move_and_slide()
	react_to_bumps(speed_before_moving)
	react_to_starting_and_stopping(input_direction)
	if input_direction != Vector2.ZERO:
		look.look_direction = look.look_direction.lerp(input_direction.normalized(), 12.0 * delta).normalized()


func react_to_bumps(speed_before_moving: float) -> void:
	if speed_before_moving < mover.top_speed * 0.6:
		return
	for collision_index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(collision_index)
		var hit_head_on: bool = collision.get_normal().dot(velocity.normalized()) < -0.5 or velocity.length() < 40.0
		if hit_head_on:
			look.squash_stretch.kick(Vector2(-9.0, 7.0))
			bumped_into_something.emit()
			return


func react_to_starting_and_stopping(input_direction: Vector2) -> void:
	var is_moving: bool = input_direction != Vector2.ZERO
	if is_moving and not was_moving:
		look.squash_stretch.kick(Vector2(6.0, -5.0))
	elif was_moving and not is_moving:
		look.squash_stretch.kick(Vector2(-5.0, 4.0))
	was_moving = is_moving
