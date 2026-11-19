class_name ClockMode
extends Node2D
## Clock mode: a big clock on the left to wind with left and right, and the
## blob household's house on the right that shows what's happening at that
## time of day. One press winds one step of the rung; holding speeds up.

const CLOCK_CENTRE: Vector2 = Vector2(480, 540)
## The house fills the space right of the clock, under the banner.
const HOUSE_BOX: Rect2 = Rect2(895, 175, 1000, 890)
## The read answers sit under the clock, their bottoms on this line.
const ANSWER_CARDS_BOTTOM: float = 1066.0
## The answer cards stay this far clear of the house and the screen's left edge.
const ANSWER_CARDS_MARGIN: float = 20.0
## Every visit starts at 7 in the morning.
const STARTING_MINUTES: int = 7 * 60
const SECONDS_TO_CHEER: float = 3.0
const RUNG_8_CONTROLS: String = "Tap: 1 minute · Hold: 5 minutes"

## The rung picked on the Clock menu.
static var rung_to_play: int = 1
## The rung just finished, so the Clock menu can start on the next one (0 for none).
static var rung_just_finished: int = 0
## Tricky replay, chosen on the Clock menu: each card deals a random unlocked
## tricky face. Kept for the session, so the menu comes back in tricky mode.
static var tricky_replay: bool = false

var rung: int = 1
## Whether this is the rung being climbed: only its deck is saved, and only
## finishing it clears a rung. Replays (and rungs opened by a grown-up) aren't.
var is_climbing: bool = false
var clock_face: ClockFace
var house: ClockHouse
var winder: ClockWinder = ClockWinder.new()
var controls_hint: ControlsHint
var effects_layer: Node2D
var task_banner: ClockTaskBanner
var answer_cards: ClockAnswerCards
var task_runner: ClockTaskRunner
## Minutes wound since midnight on the first day. Not wrapped, so the hands
## sweep forwards across midnight; minutes_of_the_day() wraps it.
var wound_minutes: int = STARTING_MINUTES
## Whether left and right wind the hands. Off while the clock winds itself.
var player_can_wind: bool = true


func _ready() -> void:
	Music.play_track("clock")
	add_to_group("gameplay")
	clock_face = ClockFace.new()
	clock_face.name = "ClockFace"
	clock_face.position = CLOCK_CENTRE
	add_child(clock_face)
	house = ClockHouse.new()
	house.name = "House"
	house.fit_into(HOUSE_BOX)
	add_child(house)
	rung = rung_to_play
	is_climbing = not tricky_replay and rung == ClockRungs.climbing_rung(GameSettings.get_progress("clock_rungs_cleared"))
	effects_layer = Node2D.new()
	effects_layer.name = "Effects"
	add_hud()
	task_runner = ClockTaskRunner.new(self)
	task_runner.name = "TaskRunner"
	add_child(task_runner)
	task_runner.card_finished.connect(on_card_finished)
	task_runner.card_started.connect(on_card_started)
	task_runner.deck_finished.connect(on_deck_finished)
	task_runner.start_deck(rung, first_deck(), true)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	hud.add_child(controls_hint)
	hud.add_child(effects_layer)
	task_banner = ClockTaskBanner.new()
	hud.add_child(task_banner)
	answer_cards = ClockAnswerCards.new()
	answer_cards.visible = false
	hud.add_child(answer_cards)
	answer_cards.bottom_y = ANSWER_CARDS_BOTTOM
	answer_cards.position = Vector2(answer_cards_left(answer_cards.size.x), ANSWER_CARDS_BOTTOM - answer_cards.size.y)


## Centred under the clock where they fit, nudged left so they never cover the house.
static func answer_cards_left(cards_width: float) -> float:
	var centred_left: float = CLOCK_CENTRE.x - cards_width / 2.0
	var furthest_right_left: float = HOUSE_BOX.position.x - ANSWER_CARDS_MARGIN - cards_width
	return maxf(ANSWER_CARDS_MARGIN, minf(centred_left, furthest_right_left))


## The climbing rung picks up its saved deck where it left off (or deals and
## saves a new one). Replays always deal a fresh shuffle.
func first_deck() -> Array[ClockCard]:
	if is_climbing:
		var saved_deck: Array[ClockCard] = cards_from_saved_numbers(GameSettings.get_clock_task_deck())
		if not saved_deck.is_empty():
			return saved_deck
	var new_deck: Array[ClockCard] = ClockDeck.deal(rung, task_runner.random)
	if is_climbing:
		save_deck(new_deck)
	return new_deck


func cards_from_saved_numbers(saved_numbers: Array[int]) -> Array[ClockCard]:
	var cards: Array[ClockCard] = []
	var rung_times: Array[int] = ClockRungs.times_of_the_day(rung)
	for saved_number in saved_numbers:
		var card: ClockCard = ClockCard.from_saved_number(saved_number)
		# A saved card that isn't one of this rung's times is from an old save: skip it
		if rung_times.has(card.minutes_of_the_day):
			cards.append(card)
	return cards


func save_deck(cards: Array[ClockCard]) -> void:
	var saved_numbers: Array[int] = []
	for card in cards:
		saved_numbers.append(card.saved_number())
	GameSettings.set_clock_task_deck(saved_numbers)


## On a tricky replay, every card deals a random unlocked tricky face.
func on_card_started(_card: ClockCard) -> void:
	if not tricky_replay:
		return
	var faces: Array[String] = ClockRungs.tricky_faces_for(rung, GameSettings.get_progress("clock_rungs_cleared"), GameSettings.get_setting("open_all_clock_rungs") == 1)
	if faces.is_empty():
		return
	clock_face.show_face(faces[task_runner.random.randi() % faces.size()])


## On the climbing rung, the cards still to come are saved after each one.
func on_card_finished(_card: ClockCard) -> void:
	if is_climbing:
		save_deck(task_runner.deck.slice(task_runner.card_index + 1))


## Finishing the climbing rung's deck clears it: the next rung (and a tricky
## face) opens. Then back to the Clock menu, on the next rung.
func on_deck_finished() -> void:
	var cheer: String = "Well done!"
	var new_face: String = ""
	if is_climbing:
		GameSettings.record_progress("clock_rungs_cleared", rung)
		GameSettings.set_clock_task_deck([])
		cheer = "You cleared %s!" % ClockRungs.title(rung)
		new_face = ClockRungs.TRICKY_FACES[rung - 1]
		effects_layer.add_child(Confetti.new())
	Sound.play("chime", 0.0, 1.25)
	task_banner.celebrate()
	if new_face == "":
		task_banner.show_text(cheer)
	else:
		# The new tricky clock shows itself off
		task_banner.show_text(cheer, "A new tricky clock!")
		clock_face.show_face(new_face)
	rung_just_finished = rung
	await get_tree().create_timer(SECONDS_TO_CHEER).timeout
	SceneManager.go_to("res://ui/clock_menu.tscn")


func show_rung(new_rung: int) -> void:
	rung = new_rung
	clock_face.shows_minute_hand = ClockRungs.shows_minute_hand(rung)
	clock_face.minute_hand_reach = 1.0
	controls_hint.caption = RUNG_8_CONTROLS if rung == ClockRungs.SINGLE_MINUTES_RUNG else ""
	clock_face.queue_redraw()


func _process(delta: float) -> void:
	house.live_minutes_of_the_day = clock_face.shown_minutes
	var direction: int = 0
	if player_can_wind:
		direction = held_direction()
	var steps: int = winder.update(direction, delta)
	if steps == 0:
		return
	if rung == ClockRungs.SINGLE_MINUTES_RUNG and winder.is_repeating():
		wind_in_fives(steps)
	else:
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
	Sound.play("tick", 0.02, 1.0 + 0.12 * signi(steps))


func start_the_day() -> void:
	wound_minutes = STARTING_MINUTES
	clock_face.jump_to(wound_minutes)
	house.live_minutes_of_the_day = wound_minutes
	house.show_moment(wound_minutes)


## Rung 8's hold: each repeat goes on to the next five, so a hold from
## 3:17 lands on 3:20, 3:25... and a tap still counts single minutes.
func wind_in_fives(repeats: int) -> void:
	for repeat in absi(repeats):
		wound_minutes += ClockWinder.minutes_to_the_next_five(minutes_of_the_day(), signi(repeats))
	clock_face.wind_to(wound_minutes)
	Sound.play("tick", 0.02, 1.0 + 0.12 * signi(repeats))


## The clock winds itself, over a set time however far it is.
func wind_itself_by(minutes: int, seconds: float) -> void:
	wound_minutes += minutes
	await clock_face.sweep_to(wound_minutes, seconds)


## The time the clock shows, 0 to 1439.
func minutes_of_the_day() -> int:
	return ClockTime.wound(wound_minutes, 0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), PaintColours.CREAM)
