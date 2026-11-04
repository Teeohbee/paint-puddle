class_name SpelledThing
extends Node2D
## Something a word turned into: spell DOG and a dog pops out of the last
## letter, then hops about the meadow. It never gets in the way - nothing
## bumps into it. When the meadow gets too full the oldest waves goodbye
## and hops off the edge.

const HOP_HEIGHT: float = 10.0
const HOPS_PER_SECOND: float = 2.2
const WANDER_SPEED: float = 70.0
const LEAVING_SPEED: float = 260.0
## The meadow's grass inside the hedge.
const MEADOW_AREA: Rect2 = Rect2(140, 200, 1640, 740)

var thing_name: String = "dog"
## Where it may wander: a spot is fine if this returns true. Set by the meadow.
var is_good_spot: Callable = func(_spot: Vector2) -> bool: return true
var target: Vector2
var seconds_resting: float = 0.0
var is_leaving: bool = false
var picture: ThingPicture

## Picture pose, put together into the picture's transform every frame.
var growth: float = 1.0
var facing: float = 1.0
var hop_time: float = randf() * 10.0
var hop_lift: float = 0.0
var hop_squash: float = 1.0
var jump_lift: float = 0.0
var spin: float = 0.0
var is_jumping: bool = false


func _ready() -> void:
	picture = ThingPicture.new()
	picture.thing_name = thing_name
	add_child(picture)
	target = position
	seconds_resting = randf_range(0.8, 1.6)


## Pops up out of the ground with a bounce.
func pop_in() -> void:
	growth = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "growth", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not is_jumping:
		move(delta)
	picture.position = Vector2(0, -hop_lift - jump_lift)
	picture.rotation = spin
	picture.scale = Vector2(facing * (2.0 - hop_squash), hop_squash) * growth
	queue_redraw()


func move(delta: float) -> void:
	if is_leaving:
		position = position.move_toward(target, LEAVING_SPEED * delta)
		hop(delta, 1.6)
		if position == target:
			queue_free()
		return
	if seconds_resting > 0.0:
		seconds_resting -= delta
		hop_lift = move_toward(hop_lift, 0.0, 60.0 * delta)
		hop_squash = move_toward(hop_squash, 1.0, 2.0 * delta)
		if seconds_resting <= 0.0:
			target = pick_next_spot()
		return
	position = position.move_toward(target, WANDER_SPEED * delta)
	face_towards(target)
	hop(delta, 1.0)
	if position == target:
		seconds_resting = randf_range(1.5, 4.0)


func hop(delta: float, speed_scale: float) -> void:
	hop_time += delta * HOPS_PER_SECOND * speed_scale
	var hop_phase: float = fmod(hop_time, 1.0)
	hop_lift = absf(sin(hop_phase * PI)) * HOP_HEIGHT
	hop_squash = 1.0 - 0.08 * cos(hop_phase * TAU)


## The pictures face left, so moving right flips them.
func face_towards(spot: Vector2) -> void:
	if absf(spot.x - position.x) >= 1.0:
		facing = 1.0 if spot.x < position.x else -1.0


## Somewhere near to hop to, or anywhere clear if it's boxed in.
func pick_next_spot() -> Vector2:
	for attempt in 30:
		var spot: Vector2 = position + Vector2.from_angle(randf() * TAU) * randf_range(120, 380)
		if MEADOW_AREA.has_point(spot) and is_good_spot.call(spot):
			return spot
	for attempt in 60:
		var spot: Vector2 = MEADOW_AREA.position + Vector2(randf(), randf()) * MEADOW_AREA.size
		if is_good_spot.call(spot):
			return spot
	return position


## A happy jump and a spin, then off out of the nearest side of the meadow.
func wave_goodbye() -> void:
	if is_leaving:
		return
	is_leaving = true
	is_jumping = true
	var jump: Tween = create_tween()
	jump.tween_property(self, "jump_lift", 50.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	jump.parallel().tween_property(self, "spin", TAU, 0.5)
	jump.tween_property(self, "jump_lift", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await jump.finished
	spin = 0.0
	var leaves_left: bool = position.x < 960.0
	target = Vector2(-120.0 if leaves_left else 2040.0, position.y)
	face_towards(target)
	is_jumping = false


func _draw() -> void:
	draw_set_transform(Vector2(0, ThingDrawings.GROUND_Y), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 50.0 * growth * (1.0 - hop_lift / 60.0), Color(0.1, 0.25, 0.05, 0.2))
	draw_set_transform(Vector2.ZERO)


class ThingPicture extends Node2D:
	var thing_name: String = "dog"

	func _draw() -> void:
		ThingDrawings.draw(self, thing_name)
