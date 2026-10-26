class_name TopDownMover
extends RefCounted
## Turns a D-pad or stick direction into a velocity for the meadow. Quick to
## start, quicker to stop, so small hands can line up on things.

var top_speed: float = 360.0
var speeding_up_rate: float = 2000.0
var slowing_down_rate: float = 2600.0


func next_velocity(current_velocity: Vector2, input_direction: Vector2, delta: float) -> Vector2:
	# A D-pad diagonal arrives as (1, 1); limiting it stops diagonals being faster
	var wanted_velocity: Vector2 = input_direction.limit_length(1.0) * top_speed
	var is_slowing_or_turning: bool = wanted_velocity.length() < current_velocity.length() \
		or wanted_velocity.dot(current_velocity) < 0.0
	var rate: float = slowing_down_rate if is_slowing_or_turning else speeding_up_rate
	return current_velocity.move_toward(wanted_velocity, rate * delta)
