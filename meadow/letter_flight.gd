class_name LetterFlight
extends Node
## Flies its parent letter stone round a figure of eight about the spot it was
## put down (Meadow Medium). The loop is fitted to the spot: lying down or
## upright, as big as fits up to LOOP_SIZE without crossing anything to keep
## clear of or leaving the meadow. Played with him: size 90, speed 0.5.

const LOOP_SIZE: float = 90.0
const LOOP_SPEED: float = 0.5
## Every flying spot has at least this much room.
const ROOMY_LOOP: float = 30.0
const SHRINK_STEP: float = 5.0
## Where a stone's centre can go: clear of the hedge, and of the banner with
## the butterfly's antennae.
const MEADOW_INSIDE: Rect2 = Rect2(130, 240, 1660, 710)
const PATH_SAMPLES: int = 64

var home: Vector2
var loop_size: float = LOOP_SIZE
var is_upright: bool = false
var phase: float = randf() * TAU
var time: float = 0.0


## Where the loop has the stone at time t: across twice as far as up and down.
static func loop_offset(t: float, size: float, upright: bool) -> Vector2:
	var lying_down: Vector2 = Vector2(sin(t) * 2.0, sin(t * 2.0)) * size
	return Vector2(lying_down.y, lying_down.x) if upright else lying_down


static func loop_fits(home_spot: Vector2, size: float, upright: bool, places_to_keep_clear: Array) -> bool:
	for step in PATH_SAMPLES:
		var point: Vector2 = home_spot + loop_offset(TAU * step / PATH_SAMPLES, size, upright)
		if not MEADOW_INSIDE.has_point(point):
			return false
		for place in places_to_keep_clear:
			if is_inside(point, place):
				return false
	return true


## A place is a circle, {"centre", "radius"}, or only the part of one above
## "only_above_y" (the rainbow's arch).
static func is_inside(point: Vector2, place: Dictionary) -> bool:
	if place.has("only_above_y") and point.y > place.only_above_y:
		return false
	return point.distance_to(place.centre) < place.radius


## The biggest loop that fits here, as {"size", "upright"}. Size 0 stays still.
static func fitted_loop(home_spot: Vector2, places_to_keep_clear: Array) -> Dictionary:
	var size: float = LOOP_SIZE
	while size > 0.0:
		for upright in [false, true]:
			if loop_fits(home_spot, size, upright, places_to_keep_clear):
				return {"size": size, "upright": upright}
		size -= SHRINK_STEP
	return {"size": 0.0, "upright": false}


func _init(home_spot: Vector2, places_to_keep_clear: Array) -> void:
	home = home_spot
	var loop: Dictionary = fitted_loop(home_spot, places_to_keep_clear)
	loop_size = loop.size
	is_upright = loop.upright


## Where the stone starts, so it doesn't jump on the first frame.
func start_position() -> Vector2:
	return home + loop_offset(phase, loop_size, is_upright)


func _physics_process(delta: float) -> void:
	var stone: Node2D = get_parent()
	if stone == null or stone.is_leaving:
		return
	time += delta
	stone.position = home + loop_offset(time * LOOP_SPEED + phase, loop_size, is_upright)
