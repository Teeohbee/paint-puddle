class_name ClockMode
extends Node2D
## Clock mode: a big clock on the left to wind with left and right, and the
## blob household's house on the right that shows what's happening at that
## time of day. One press winds one step of the rung; holding speeds up.

const CLOCK_CENTRE: Vector2 = Vector2(480, 540)
## The read answers sit under the clock, their bottoms on this line.
const ANSWER_CARDS_BOTTOM: float = 1066.0
## Every visit starts at 7 in the morning.
const STARTING_MINUTES: int = 7 * 60
## Until the rung menu exists, the clock winds like rung 3: half an hour a press.
const FIRST_RUNG: int = 3

var rung: int = FIRST_RUNG
var clock_face: ClockFace
var winder: ClockWinder = ClockWinder.new()
var controls_hint: ControlsHint
var task_banner: ClockTaskBanner
var answer_cards: ClockAnswerCards
var task_runner: ClockTaskRunner
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
	add_hud()
	task_runner = ClockTaskRunner.new(self)
	task_runner.name = "TaskRunner"
	add_child(task_runner)
	task_runner.deck_finished.connect(start_a_new_deck)
	start_a_new_deck()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	hud.add_child(controls_hint)
	task_banner = ClockTaskBanner.new()
	hud.add_child(task_banner)
	answer_cards = ClockAnswerCards.new()
	answer_cards.visible = false
	hud.add_child(answer_cards)
	answer_cards.bottom_y = ANSWER_CARDS_BOTTOM
	answer_cards.position = Vector2(CLOCK_CENTRE.x - answer_cards.size.x / 2.0, ANSWER_CARDS_BOTTOM - answer_cards.size.y)


## Until the rung menu exists, deck after deck of the first rung.
func start_a_new_deck() -> void:
	task_runner.start_deck(rung, ClockDeck.deal(rung, task_runner.random))


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


func start_the_day() -> void:
	wound_minutes = STARTING_MINUTES
	clock_face.jump_to(wound_minutes)


## The clock winds itself, over a set time however far it is.
func wind_itself_by(minutes: int, seconds: float) -> void:
	wound_minutes += minutes
	await clock_face.sweep_to(wound_minutes, seconds)


## The time the clock shows, 0 to 1439.
func minutes_of_the_day() -> int:
	return ClockTime.wound(wound_minutes, 0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), PaintColours.CREAM)
