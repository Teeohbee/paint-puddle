class_name ClockWinder
extends RefCounted
## Turns left and right on the D-pad into steps of the clock. One press is
## one step, straight away. Holding waits a moment, then repeats, getting
## quicker each time up to about 40 steps a second, so a long way round
## doesn't take forever. It never slows near the answer: that would give
## the answer away.
##
## The caller says each frame which way is held (-1, 0 or 1) and how long
## the frame was, and gets back how many steps to wind (negative is back).

const FIRST_REPEAT_DELAY_SECONDS: float = 0.35
const FIRST_REPEAT_GAP_SECONDS: float = 0.18
const GAP_SHRINK_PER_REPEAT: float = 0.82
const SHORTEST_GAP_SECONDS: float = 0.025

var held_direction: int = 0
var seconds_held: float = 0.0
var next_repeat_at_seconds: float = 0.0
var repeats_this_hold: int = 0


## How many steps to wind this frame: 1 or -1 on a fresh press, then the
## repeats that fall due while it's held.
func update(direction: int, delta: float) -> int:
	if direction == 0:
		held_direction = 0
		return 0
	if direction != held_direction:
		start_holding(direction)
		return direction
	seconds_held += delta
	var steps: int = 0
	while seconds_held >= next_repeat_at_seconds:
		next_repeat_at_seconds += gap_after_repeat(repeats_this_hold)
		repeats_this_hold += 1
		steps += direction
	return steps


func start_holding(direction: int) -> void:
	held_direction = direction
	seconds_held = 0.0
	repeats_this_hold = 0
	next_repeat_at_seconds = FIRST_REPEAT_DELAY_SECONDS


## The wait before the next repeat, counted from the one just made.
func gap_after_repeat(repeat_number: int) -> float:
	return maxf(FIRST_REPEAT_GAP_SECONDS * pow(GAP_SHRINK_PER_REPEAT, repeat_number), SHORTEST_GAP_SECONDS)


## True once a hold has started repeating, rather than a single press.
func is_repeating() -> bool:
	return held_direction != 0 and repeats_this_hold > 0


## On rung 8 a tap moves one minute, and each repeat of a hold moves on to
## the next five in the direction it's winding: backwards from 3:17 it goes
## to 3:15, then 3:10. Returns the minutes to wind (negative is back).
static func minutes_to_the_next_five(minutes_of_the_day: int, direction: int) -> int:
	var past_a_five: int = minutes_of_the_day % 5
	if direction > 0:
		return 5 - past_a_five
	if past_a_five == 0:
		return -5
	return -past_a_five
