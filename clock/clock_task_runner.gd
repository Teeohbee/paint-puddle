class_name ClockTaskRunner
extends Node
## Plays a deck of Clock mode cards, one at a time.
##
## Time only goes forward, and the face can't tell morning from evening, so
## a card's time is the next time the face shows it (its target), and its
## moment is whatever the house is doing then.
##
## A set card gives a time; the player winds the hands on and presses A.
## A read card winds the clock itself on to a time, then offers three answers
## under the clock.
##
## Right: a chime, the middle blob cheers, a star if it was the first try,
## and the house acts out the moment. Wrong is clearly wrong but gentle: a
## soft boing, the blob shakes its head, a wrong answer card greys out where
## it is, and the house stays put. Then help comes, one step per miss: the
## number glows, then (on set cards) see-through ghost hands show where to
## go, then the banner explains it in words.

signal card_started(card: ClockCard)
## first_try: answered right with no miss before it (so no help either).
signal card_finished(card: ClockCard, first_try: bool)
signal deck_finished
## The copy turn of a rung's intro is done.
signal copied

enum State { BETWEEN_CARDS, SETTING, CHOOSING, COPYING }

const SECONDS_TO_WIND_TO_A_READ_TIME: float = 1.5
const SECONDS_TO_CELEBRATE: float = 1.6
const SECONDS_TO_SHOW_A_MESSAGE: float = 2.6
## Help, one step per miss on the same card: the glow comes on the first.
const MISSES_BEFORE_THE_GHOST: int = 2
const MISSES_BEFORE_THE_EXPLANATION: int = 3
## From this rung the minute mark glows too, not just the number.
const FIRST_RUNG_TO_GLOW_THE_MINUTES: int = 4
const SECONDS_FOR_THE_INTRO_LAP: float = 3.0
const SECONDS_TO_WIND_IN_THE_INTRO: float = 1.5
const SECONDS_TO_WATCH: float = 2.5
## Each rung's intro: the time the blob shows, then a different one he copies.
## Rungs without one use their example time and two hours on.
const INTRO_TIMES: Dictionary = {
	1: [3 * 60, 5 * 60],
	2: [3 * 60 + 30, 5 * 60 + 30],
	3: [3 * 60, 5 * 60 + 30],
}

var mode: ClockMode
var rung: int = 1
var deck: Array[ClockCard] = []
var card_index: int = 0
var current_card: ClockCard
## The current card's time, as the next time the face shows it.
var target_minutes: int = 0
var misses: int = 0
## The time to copy in a rung's intro.
var copy_target: int = 0
## Cards right first time this deck, one star each.
var stars_earned: int = 0
var state: State = State.BETWEEN_CARDS
var random: RandomNumberGenerator = RandomNumberGenerator.new()
## Counts messages, so an old message's timer doesn't put back a card that has moved on.
var messages_shown: int = 0


func _init(clock_mode: ClockMode) -> void:
	mode = clock_mode
	random.randomize()


## Every deck starts at 7 in the morning, and the day carries on from card to
## card. The first time a rung opens, a short intro shows what's new on it.
func start_deck(new_rung: int, new_deck: Array[ClockCard], with_intro: bool = false) -> void:
	rung = new_rung
	deck = new_deck
	card_index = 0
	current_card = null
	stars_earned = 0
	mode.task_banner.set_stars(0, deck.size())
	state = State.BETWEEN_CARDS
	mode.show_rung(rung)
	mode.answer_cards.hide_answers()
	mode.start_the_day()
	if with_intro and GameSettings.get_progress("clock_rung_intros_seen") < rung:
		await play_intro(new_deck)
		if deck != new_deck:
			return
		GameSettings.record_progress("clock_rung_intros_seen", rung)
		mode.start_the_day()
	play_card()


## Rung 3 first brings the minute hand on, and rung 8 counts single minutes;
## then every rung shows its idea and lets him copy it.
func play_intro(this_deck: Array[ClockCard]) -> void:
	mode.player_can_wind = false
	if rung == ClockRungs.FIRST_RUNG_WITH_THE_MINUTE_HAND:
		await play_minute_hand_intro()
	elif rung == ClockRungs.SINGLE_MINUTES_RUNG:
		await play_single_minutes_intro()
	mode.clock_face.clear_lit_minutes()
	if deck != this_deck:
		return
	await show_then_copy(this_deck)


## "Watch!": the blob winds to a time and says how to read it. Then "Your
## turn": he winds to another, with ghost hands showing where. The copy turn
## never counts towards moving up.
func show_then_copy(this_deck: Array[ClockCard]) -> void:
	var times: Array = INTRO_TIMES.get(rung, [ClockRungs.example_minutes(rung), ClockTime.wound(ClockRungs.example_minutes(rung), 120)])
	mode.task_banner.show_text("Watch!", explanation_for(times[0], rung))
	await mode.wind_itself_by(ClockTime.minutes_until_the_face_shows(mode.minutes_of_the_day(), times[0]), SECONDS_TO_WIND_IN_THE_INTRO)
	if deck != this_deck:
		return
	await get_tree().create_timer(SECONDS_TO_WATCH).timeout
	if deck != this_deck:
		return
	copy_target = ClockTime.wound(mode.minutes_of_the_day(), ClockTime.minutes_until_the_face_shows(mode.minutes_of_the_day(), times[1]))
	mode.clock_face.show_ghost_hand(copy_target)
	mode.task_banner.show_text("Your turn - make it %s" % ClockTime.time_words(times[1]))
	state = State.COPYING
	mode.player_can_wind = true
	await copied


func confirm_copy() -> void:
	if not ClockTime.faces_match(mode.minutes_of_the_day(), copy_target):
		Sound.play("wobble", 0.02)
		mode.clock_face.shake_blob()
		return
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
	mode.clock_face.clear_ghost_hand()
	mode.clock_face.cheer_blob()
	Sound.play("chime")
	mode.task_banner.celebrate()
	mode.task_banner.show_text("Yes! It's %s" % ClockTime.time_words(copy_target))
	var this_deck: Array[ClockCard] = deck
	await get_tree().create_timer(SECONDS_TO_CELEBRATE).timeout
	if deck == this_deck:
		copied.emit()


## Rung 3: the big minute hand slides on, then goes once round while the
## little hour hand creeps on to the next number.
func play_minute_hand_intro() -> void:
	mode.clock_face.set_minute_hand_reach(0.0)
	mode.task_banner.show_text("Meet the big minute hand!", "It shows the minutes")
	await get_tree().create_timer(0.8).timeout
	var slide_on: Tween = create_tween()
	slide_on.tween_method(mode.clock_face.set_minute_hand_reach, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await slide_on.finished
	await get_tree().create_timer(1.4).timeout
	mode.task_banner.show_text("All the way round is an hour", "and the little hour hand moves on to the next number")
	await mode.wind_itself_by(ClockTime.MINUTES_IN_AN_HOUR, SECONDS_FOR_THE_INTRO_LAP)
	await get_tree().create_timer(1.6).timeout


## Rung 8: a hold sweeps on to quarter past in fives, then three taps count
## 16, 17, 18 with the marks lighting up.
func play_single_minutes_intro() -> void:
	mode.task_banner.show_text("Hold to go in fives. Tap to count the minutes.")
	await get_tree().create_timer(1.2).timeout
	for five in 3:
		await mode.wind_itself_by(5, 0.3)
	await get_tree().create_timer(0.6).timeout
	for tap in 3:
		await mode.wind_itself_by(1, 0.25)
		mode.clock_face.light_minute(mode.minutes_of_the_day() % ClockTime.MINUTES_IN_AN_HOUR)
		Sound.play("pop", 0.02, 1.0 + tap * 0.12)
		await get_tree().create_timer(0.45).timeout
	await get_tree().create_timer(1.2).timeout


func play_card() -> void:
	current_card = deck[card_index]
	target_minutes = ClockTime.wound(mode.minutes_of_the_day(), minutes_to_the_target())
	misses = 0
	mode.clock_face.clear_ghost_hand()
	card_started.emit(current_card)
	if current_card.is_read:
		play_read_card()
	else:
		play_set_card()


func minutes_to_the_target() -> int:
	return ClockTime.minutes_until_the_face_shows(mode.minutes_of_the_day(), current_card.minutes_of_the_day)


func play_set_card() -> void:
	state = State.SETTING
	mode.player_can_wind = true
	mode.controls_hint.shows_left = false
	show_set_card_text()


func show_set_card_text() -> void:
	mode.task_banner.show_text(set_card_words(target_minutes), help_line())


## The explanation, once he's missed twice already; nothing before that.
func help_line() -> String:
	if misses >= MISSES_BEFORE_THE_EXPLANATION:
		return explanation_for(target_minutes, rung)
	return ""


## Says how to read the time from the hands, the way the rung teaches it:
## the hour hand alone below rung 3, the minute hand first from there.
static func explanation_for(time: int, for_rung: int) -> String:
	var hour: int = ClockTime.hour_on_the_face(time)
	var next_hour: int = ClockTime.hour_on_the_face(ClockTime.wound(time, ClockTime.MINUTES_IN_AN_HOUR))
	var minute: int = time % ClockTime.MINUTES_IN_AN_HOUR
	var with_minute_hand: bool = ClockRungs.shows_minute_hand(for_rung)
	if minute == 0:
		if with_minute_hand:
			return "The minute hand is on 12 and the hour hand points at the %d. It's %d o'clock!" % [hour, hour]
		return "The hour hand points at the %d. It's %d o'clock!" % [hour, hour]
	if minute == 30:
		if with_minute_hand:
			return "The minute hand is on 6 and the hour hand is halfway from %d to %d. It's half past %d!" % [hour, next_hour, hour]
		return "The hour hand is halfway from %d to %d. It's half past %d!" % [hour, next_hour, hour]
	return "It's %s!" % ClockTime.time_words(time)


## "Bath time - make it half past 6": the moment, then the time.
static func set_card_words(time: int) -> String:
	return "%s - make it %s" % [DayMoments.moment_at(time)["name"], ClockTime.time_words(time)]


func play_read_card() -> void:
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
	mode.controls_hint.shows_left = true
	mode.task_banner.show_text("What time is it?")
	var this_card: ClockCard = current_card
	await mode.wind_itself_by(minutes_to_the_target(), SECONDS_TO_WIND_TO_A_READ_TIME)
	if this_card != current_card:
		return
	# Once the clock has wound the blobs play this card's moment. (Set cards keep
	# them back until A, so watching the house can't solve those.)
	mode.house.show_moment(target_minutes)
	var answers: Array[int] = ClockDeck.read_answers(rung, target_minutes, random)
	mode.answer_cards.show_answers(answers)
	state = State.CHOOSING


func _process(_delta: float) -> void:
	match state:
		State.SETTING:
			if Input.is_action_just_pressed("act"):
				confirm_set_time()
		State.COPYING:
			if Input.is_action_just_pressed("act"):
				confirm_copy()
		State.CHOOSING:
			if Input.is_action_just_pressed("move_left"):
				mode.answer_cards.move_choice(-1)
			elif Input.is_action_just_pressed("move_right"):
				mode.answer_cards.move_choice(1)
			elif Input.is_action_just_pressed("act"):
				choose_answer()


func confirm_set_time() -> void:
	var made: int = mode.minutes_of_the_day()
	if ClockTime.faces_match(made, target_minutes):
		finish_card()
		return
	misses += 1
	react_to_a_miss()
	show_message_then_the_card("Not quite - try again!", set_card_words(target_minutes))


## Clearly wrong, but gentle - then the next step of help.
func react_to_a_miss() -> void:
	Sound.play("wobble", 0.02)
	mode.clock_face.shake_blob()
	glow_the_target()
	if not current_card.is_read and misses >= MISSES_BEFORE_THE_GHOST:
		mode.clock_face.show_ghost_hand(target_minutes)


func show_message_then_the_card(main_text: String, small_text: String) -> void:
	messages_shown += 1
	var this_message: int = messages_shown
	var this_card: ClockCard = current_card
	mode.task_banner.show_text(main_text, small_text)
	await get_tree().create_timer(SECONDS_TO_SHOW_A_MESSAGE).timeout
	if this_message == messages_shown and this_card == current_card and state == State.SETTING:
		show_set_card_text()


## The number the time is named by ("quarter to 4" glows the 4) and, from
## rung 4, the minute mark the minute hand should reach.
func glow_the_target() -> void:
	var time: int = target_minutes
	var minute: int = time % ClockTime.MINUTES_IN_AN_HOUR
	var named_hour: int = ClockTime.hour_on_the_face(time)
	if minute > 30:
		named_hour = ClockTime.hour_on_the_face(ClockTime.wound(time, ClockTime.MINUTES_IN_AN_HOUR))
	var glowing_minute: int = -1
	if rung >= FIRST_RUNG_TO_GLOW_THE_MINUTES:
		glowing_minute = minute
	mode.clock_face.glow_target(named_hour, glowing_minute)


func choose_answer() -> void:
	var picked: int = mode.answer_cards.chosen_answer()
	if picked == target_minutes:
		mode.answer_cards.hide_answers()
		finish_card()
		return
	misses += 1
	mode.answer_cards.grey_out_chosen()
	react_to_a_miss()
	mode.task_banner.show_text("What time is it?", help_line())


func finish_card() -> void:
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
	Sound.play("chime")
	mode.clock_face.clear_ghost_hand()
	mode.clock_face.cheer_blob()
	# Where the hands really are: a lap on from the target reads the same but is the other half of the day
	mode.house.show_moment(mode.minutes_of_the_day())
	if misses == 0:
		stars_earned += 1
		mode.task_banner.set_stars(stars_earned, deck.size())
	mode.task_banner.celebrate()
	mode.task_banner.show_text("Yes! It's %s" % ClockTime.time_words(target_minutes))
	var finished: ClockCard = current_card
	card_finished.emit(finished, misses == 0)
	await get_tree().create_timer(SECONDS_TO_CELEBRATE).timeout
	if finished != current_card:
		return
	card_index += 1
	if card_index >= deck.size():
		deck_finished.emit()
		return
	play_card()
