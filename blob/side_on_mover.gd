class_name SideOnMover
extends RefCounted
## The jump and run rules for the hills, kept apart from physics so they can
## be tested. Very forgiving on purpose:
## - coyote time: a jump still works a moment after walking off an edge
## - jump buffer: a jump pressed just before landing happens on landing
## - holding the button floats the top of the jump (half gravity)
## - letting go early makes a smaller hop
## - letting go in the air keeps the sideways speed, so one tap carries
## - jumping from still while holding a direction gives a run-up for free

var walk_speed: float = 300.0
var speeding_up_rate: float = 1800.0
var air_speeding_up_rate: float = 3000.0
var slowing_down_rate: float = 2600.0
var gravity: float = 2200.0
var jump_speed: float = 900.0
var top_fall_speed: float = 1000.0
var coyote_seconds: float = 0.25
var jump_buffer_seconds: float = 0.25
var floaty_top_speed: float = 160.0
var standing_jump_boost: float = 0.7

var velocity: Vector2 = Vector2.ZERO
var seconds_since_on_floor: float = 999.0
var seconds_since_jump_pressed: float = 999.0
var is_rising_from_jump: bool = false
var jumped_this_step: bool = false
var jumps_made: int = 0


func step(delta: float, input_x: float, jump_held: bool, jump_pressed: bool, is_on_floor: bool) -> void:
	jumped_this_step = false
	seconds_since_on_floor = 0.0 if is_on_floor else seconds_since_on_floor + delta
	seconds_since_jump_pressed = 0.0 if jump_pressed else seconds_since_jump_pressed + delta
	if is_on_floor and velocity.y >= 0.0:
		is_rising_from_jump = false

	var wanted_speed: float = clampf(input_x, -1.0, 1.0) * walk_speed
	var is_coasting_in_the_air: bool = not is_on_floor and wanted_speed == 0.0
	if not is_coasting_in_the_air:
		var is_slowing_or_turning: bool = absf(wanted_speed) < absf(velocity.x) or wanted_speed * velocity.x < 0.0
		var rate: float = speeding_up_rate if is_on_floor else air_speeding_up_rate
		if is_slowing_or_turning:
			rate = slowing_down_rate
		velocity.x = move_toward(velocity.x, wanted_speed, rate * delta)

	var can_jump: bool = seconds_since_on_floor <= coyote_seconds and not is_rising_from_jump
	var wants_to_jump: bool = seconds_since_jump_pressed <= jump_buffer_seconds
	if can_jump and wants_to_jump:
		boost_standing_jump(wanted_speed)
		jump()
		return

	if is_on_floor and velocity.y >= 0.0:
		velocity.y = 0.0
		return
	var gravity_now: float = gravity
	var is_near_the_top: bool = absf(velocity.y) < floaty_top_speed
	if jump_held and is_near_the_top:
		gravity_now *= 0.5
	if is_rising_from_jump and velocity.y < 0.0 and not jump_held:
		# Let go early: cut the rise short for a little hop
		velocity.y *= 0.5
		is_rising_from_jump = false
	velocity.y = minf(velocity.y + gravity_now * delta, top_fall_speed)


## A jump from (nearly) still while holding a direction starts with most of
## a run-up, so creeping to the edge and jumping still clears the gap.
func boost_standing_jump(wanted_speed: float) -> void:
	var boosted_speed: float = wanted_speed * standing_jump_boost
	if absf(boosted_speed) > absf(velocity.x) or boosted_speed * velocity.x < 0.0:
		velocity.x = boosted_speed


func jump() -> void:
	velocity.y = -jump_speed
	is_rising_from_jump = true
	seconds_since_on_floor = 999.0
	seconds_since_jump_pressed = 999.0
	jumped_this_step = true
	jumps_made += 1
