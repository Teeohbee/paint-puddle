class_name ClockMode
extends Node2D
## Clock mode: a big clock on the left to wind on with right, and the blob
## household's house on the right that shows what's happening at that time of
## day. Time only goes forward (clockwise), so left does nothing. One press
## winds one step of the rung; holding speeds up. A word under the clock says
## the part of the day.
##
## Play with the clock (free_play) has no cards: right or A winds the day on
## and the house acts it out, on the climbing rung's hands and step. It opens
## with ClockNumberLineIntro every time.

const CLOCK_CENTRE: Vector2 = Vector2(480, 540)
## The house fills the space right of the clock, under the banner.
const HOUSE_BOX: Rect2 = Rect2(895, 175, 1000, 890)
## The read answers sit under the clock, their bottoms on this line.
const ANSWER_CARDS_BOTTOM: float = 1072.0
## The answer cards stay this far clear of the house and the screen's left edge.
const ANSWER_CARDS_MARGIN: float = 20.0
## Every visit starts at 7 in the morning.
const STARTING_MINUTES: int = 7 * 60
const SECONDS_TO_CHEER: float = 3.0
const RUNG_8_CONTROLS: String = "Tap: 1 minute · Hold: 5 minutes"
## The part-of-the-day word sits under the clock, above the read answers.
const DAY_LABEL_POSITION: Vector2 = Vector2(480, 918)

## The rung picked on the Clock menu.
static var rung_to_play: int = 1
## The rung just cleared, so the Clock menu can start on the next one (0 for none).
static var rung_just_finished: int = 0
## Tricky replay, chosen on the Clock menu: each card deals a random unlocked
## tricky face. Kept for the session, so the menu comes back in tricky mode.
static var tricky_replay: bool = false
## Play with the clock, chosen on the Clock menu: no cards, just winding.
static var free_play: bool = false

var rung: int = 1
## Whether this is the rung being climbed: only its deck is saved, and only
## its cards count towards clearing it. Replays (and rungs opened by a grown-up) aren't.
var is_climbing: bool = false
## The climbing rung's first-try run. See ClockMastery.
var mastery: ClockMastery
var clock_face: ClockFace
var day_label: ClockDayLabel
var house: ClockHouse
var winder: ClockWinder = ClockWinder.new()
var controls_hint: ControlsHint
var effects_layer: Node2D
var task_banner: ClockTaskBanner
var answer_cards: ClockAnswerCards
var task_runner: ClockTaskRunner
var intro: ClockNumberLineIntro
## After the intro is skipped with a wind button, that press mustn't also wind.
var waiting_for_wind_release: bool = false
## Minutes wound since midnight on the first day. Not wrapped, so the hands
## sweep forwards across midnight; minutes_of_the_day() wraps it.
var wound_minutes: int = STARTING_MINUTES
## Whether right winds the hands. Off while the clock winds itself.
var player_can_wind: bool = true


func _ready() -> void:
	Music.play_track("clock")
	add_to_group("gameplay")
	clock_face = ClockFace.new()
	clock_face.name = "ClockFace"
	clock_face.position = CLOCK_CENTRE
	add_child(clock_face)
	day_label = ClockDayLabel.new()
	day_label.name = "DayLabel"
	day_label.position = DAY_LABEL_POSITION
	add_child(day_label)
	house = ClockHouse.new()
	house.name = "House"
	house.fit_into(HOUSE_BOX)
	add_child(house)
	rung = rung_to_play
	is_climbing = not tricky_replay and rung == ClockRungs.climbing_rung(GameSettings.get_progress("clock_rungs_cleared"))
	mastery = ClockMastery.load_saved()
	effects_layer = Node2D.new()
	effects_layer.name = "Effects"
	add_hud()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	if free_play:
		start_free_play()
		add_child(pause_menu)
		return
	task_runner = ClockTaskRunner.new(self)
	task_runner.name = "TaskRunner"
	add_child(task_runner)
	task_runner.card_finished.connect(on_card_finished)
	task_runner.card_started.connect(on_card_started)
	task_runner.deck_finished.connect(on_deck_finished)
	task_runner.start_deck(rung, first_deck(), true)
	add_child(pause_menu)


## The climbing rung's hands and step (the top built rung once it's past them),
## from 7 in the morning, after the intro.
func start_free_play() -> void:
	is_climbing = false
	var climbing: int = ClockRungs.climbing_rung(GameSettings.get_progress("clock_rungs_cleared"))
	rung = mini(climbing if climbing > 0 else ClockRungs.RUNG_COUNT, ClockRungs.RUNGS_BUILT)
	show_rung(rung)
	controls_hint.caption = ""
	start_the_day()
	player_can_wind = false
	intro = ClockNumberLineIntro.new(clock_face)
	intro.name = "Intro"
	intro.position = CLOCK_CENTRE
	add_child(intro)
	intro.finished.connect(on_intro_finished)
	intro.play()


func on_intro_finished() -> void:
	start_the_day()
	player_can_wind = true
	waiting_for_wind_release = is_wind_held()


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	controls_hint.shows_left = false
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


## On the climbing rung, the cards still to come are saved after each one,
## and each card counts towards the first-try run. A run that clears the rung
## cheers straight away; the session carries on as a replay.
func on_card_finished(_card: ClockCard, first_try: bool) -> void:
	if not is_climbing:
		return
	save_deck(task_runner.deck.slice(task_runner.card_index + 1))
	var cleared: bool = mastery.record_answer(first_try, ClockMastery.today())
	mastery.save()
	if cleared:
		clear_the_rung()


func clear_the_rung() -> void:
	GameSettings.record_progress("clock_rungs_cleared", rung)
	GameSettings.set_clock_task_deck([])
	is_climbing = false
	rung_just_finished = rung
	effects_layer.add_child(Confetti.new())
	Sound.play("chime", 0.0, 1.25)
	task_banner.celebrate()
	task_banner.show_text("You know %s now!" % ClockRungs.title(rung))


## The end of a session: a cheer, then back to the Clock menu.
func on_deck_finished() -> void:
	Sound.play("chime", 0.0, 1.25)
	task_banner.celebrate()
	task_banner.show_text("Well done!")
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
	day_label.show_time(ClockTime.wound(int(clock_face.shown_minutes), 0))
	if intro != null and intro.is_playing():
		if any_button_just_pressed():
			intro.skip()
		return
	if waiting_for_wind_release:
		waiting_for_wind_release = is_wind_held()
		return
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


## Only forward: right winds on (and A, in free play), and nothing winds back.
func held_direction() -> int:
	return 1 if is_wind_held() else 0


func is_wind_held() -> bool:
	return Input.is_action_pressed("move_right") or (free_play and Input.is_action_pressed("act"))


func any_button_just_pressed() -> bool:
	for action in ["act", "move_right", "move_left", "move_up", "move_down"]:
		if Input.is_action_just_pressed(action):
			return true
	return false


func wind_by_steps(steps: int) -> void:
	wound_minutes += steps * ClockRungs.step_minutes(rung)
	clock_face.wind_to(wound_minutes)
	Sound.play("tick", 0.02, 1.0 + 0.12 * signi(steps))
	if free_play:
		# Nothing to work out in free play, so the blobs get on with the day straight away
		house.show_moment(minutes_of_the_day())


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
