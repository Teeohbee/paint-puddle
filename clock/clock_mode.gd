class_name ClockMode
extends Node2D
## Clock mode: a big clock on the left to wind with left and right, and the
## blob household's house on the right that shows what's happening at that
## time of day. One press winds one step of the rung; holding speeds up.

const CLOCK_CENTRE: Vector2 = Vector2(470, 560)
## Every visit starts at 7 in the morning.
const STARTING_MINUTES: int = 7 * 60
## Until the rung menu exists, the clock winds like rung 3: half an hour a press.
const FIRST_RUNG: int = 3

var rung: int = FIRST_RUNG
var clock_face: ClockFace
var winder: ClockWinder = ClockWinder.new()
var controls_hint: ControlsHint
## Minutes wound since midnight on the first day. Not wrapped, so the hands
## sweep forwards across midnight; minutes_of_the_day() wraps it.
var wound_minutes: int = STARTING_MINUTES
## Whether left and right wind the hands. Off while the clock winds itself.
var player_can_wind: bool = true


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	clock_face = ClockFace.new()
	clock_face.name = "ClockFace"
	clock_face.position = CLOCK_CENTRE
	add_child(clock_face)
	show_rung(rung)
	clock_face.jump_to(wound_minutes)
	add_hud()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	hud.add_child(controls_hint)


func show_rung(new_rung: int) -> void:
	rung = new_rung
	clock_face.shows_minute_hand = ClockRungs.shows_minute_hand(rung)
	clock_face.queue_redraw()


func _process(delta: float) -> void:
	var direction: int = 0
	if player_can_wind:
		direction = held_direction()
	var steps: int = winder.update(direction, delta)
	if steps != 0:
		wind_by_steps(steps)


func held_direction() -> int:
	var direction: int = 0
	if Input.is_action_pressed("move_right"):
		direction += 1
	if Input.is_action_pressed("move_left"):
		direction -= 1
	return direction


func wind_by_steps(steps: int) -> void:
	wound_minutes += steps * ClockRungs.step_minutes(rung)
	clock_face.wind_to(wound_minutes)
	Sound.play("move", 0.02, 1.0 + 0.15 * signi(steps))


## The time the clock shows, 0 to 1439.
func minutes_of_the_day() -> int:
	return ClockTime.wound(wound_minutes, 0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), PaintColours.CREAM)
