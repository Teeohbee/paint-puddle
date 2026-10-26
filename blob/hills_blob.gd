class_name HillsBlob
extends CharacterBody2D
## The paint blob seen from the side. Walks with the D-pad or stick and jumps
## with any face button (or up). Squashes on landing, stretches on jumping,
## and remembers the last ground it stood on so a cloud can bring it back.

signal jumped
signal landed

const BODY_RADIUS: float = 46.0
const CORNER_NUDGE_LIMIT: int = 10

var mover: SideOnMover = SideOnMover.new()
var look: PaintBlobLook
var facing: float = 1.0
var is_being_carried: bool = false
var can_move: bool = true
var was_on_floor: bool = true
var last_ground_position: Vector2


func _ready() -> void:
	floor_max_angle = deg_to_rad(50)
	floor_snap_length = 18.0
	floor_constant_speed = true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = BODY_RADIUS
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	look = PaintBlobLook.new()
	look.stretch_follows_look = false
	look.scale = Vector2(1.08, 1.08)
	look.look_direction = Vector2(1, 0.2).normalized()
	add_child(look)
	mover.coyote_seconds = GameSettings.get_setting("coyote_time_milliseconds") / 1000.0
	last_ground_position = position


func _physics_process(delta: float) -> void:
	if is_being_carried:
		return
	var input_x: float = 0.0
	var jump_held: bool = false
	var jump_pressed: bool = false
	if can_move:
		input_x = Input.get_axis("move_left", "move_right")
		jump_held = Input.is_action_pressed("act") or Input.is_action_pressed("move_up")
		jump_pressed = Input.is_action_just_pressed("act") or Input.is_action_just_pressed("move_up")
	mover.velocity = velocity
	mover.step(delta, input_x, jump_held, jump_pressed, is_on_floor())
	velocity = mover.velocity
	if mover.jumped_this_step:
		look.squash_stretch.kick(Vector2(14, -10))
		Sound.play("jump")
		jumped.emit()
	nudge_round_corners(delta)
	move_and_slide()
	react_to_landing()
	if input_x != 0.0:
		facing = signf(input_x)
	look.look_direction = look.look_direction.lerp(Vector2(facing, 0.25).normalized(), 10.0 * delta).normalized()
	if is_on_floor():
		last_ground_position = position


## Bumping a ledge corner with the top of the head slides the blob past it
## instead of stopping the jump dead.
func nudge_round_corners(delta: float) -> void:
	if velocity.y >= 0.0:
		return
	var rise: Vector2 = Vector2(0, velocity.y * delta)
	if not test_move(global_transform, rise):
		return
	for nudge in range(1, CORNER_NUDGE_LIMIT + 1):
		for direction in [facing, -facing]:
			var nudged: Transform2D = global_transform.translated(Vector2(direction * nudge, 0))
			if not test_move(nudged, rise):
				position.x += direction * nudge
				return


func react_to_landing() -> void:
	var on_floor_now: bool = is_on_floor()
	if on_floor_now and not was_on_floor:
		look.squash_stretch.kick(Vector2(-14, 12))
		Sound.play("plop", 0.05, 0.7)
		landed.emit()
	was_on_floor = on_floor_now


## Where the cloud puts the blob back: a little way back from the edge it fell from.
func safe_spot() -> Vector2:
	return last_ground_position - Vector2(facing * 90.0, 30.0)
