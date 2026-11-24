class_name ClockTaskRunner
extends Node
## Plays a deck of Clock mode cards, one at a time.
##
## Time only goes forward, and the face can't tell morning from evening, so
## a card's time is the next time the face shows it (its target), and its
## moment is whatever the house is doing then.
##
## A set card gives a time; the player winds the hands on and presses A.
## A wrong time says what time he made, then asks again, and after a second
## miss the number to aim for glows.
##
## A read card winds the clock itself on to a time, then offers three answers
## under the clock. A wrong pick winds the hands to the time he picked, shows
## it, winds back, and that card fades away so he can't go round in circles.

signal card_started(card: ClockCard)
## first_try: answered right with no miss before it (so no help either).
signal card_finished(card: ClockCard, first_try: bool)
signal deck_finished

enum State { BETWEEN_CARDS, SETTING, CHOOSING, SHOWING_A_MISTAKE }

const SECONDS_TO_WIND_TO_A_READ_TIME: float = 1.5
const SECONDS_TO_WIND_TO_A_PICKED_TIME: float = 1.0
const SECONDS_ON_A_PICKED_TIME: float = 1.6
const SECONDS_TO_CELEBRATE: float = 1.6
const SECONDS_TO_SHOW_A_MESSAGE: float = 2.6
const MISSES_BEFORE_THE_GLOW: int = 2
## From this rung the minute mark glows too, not just the number.
const FIRST_RUNG_TO_GLOW_THE_MINUTES: int = 4
const RUNGS_WITH_AN_INTRO: Array[int] = [3, 8]
const SECONDS_FOR_THE_INTRO_LAP: float = 3.0

var mode: ClockMode
var rung: int = 1
var deck: Array[ClockCard] = []
var card_index: int = 0
var current_card: ClockCard
## The current card's time, as the next time the face shows it.
var target_minutes: int = 0
var misses: int = 0
var state: State = State.BETWEEN_CARDS
var random: RandomNumberGenerator = RandomNumberGenerator.new()
## Counts messages, so an old message's timer doesn't put back a card that has moved on.
var messages_shown: int = 0


func _init(clock_mode: ClockMode) -> void:
	mode = clock_mode
	random.randomize()


## Every deck starts at 7 in the morning, and the day carries on from card to
## card. Rungs 3 and 8 can open with a short intro to what's new on them.
func start_deck(new_rung: int, new_deck: Array[ClockCard], with_intro: bool = false) -> void:
	rung = new_rung
	deck = new_deck
	card_index = 0
	current_card = null
	state = State.BETWEEN_CARDS
	mode.show_rung(rung)
	mode.answer_cards.hide_answers()
	mode.start_the_day()
	if with_intro and RUNGS_WITH_AN_INTRO.has(rung):
		await play_intro()
		if deck != new_deck:
			return
		mode.start_the_day()
	play_card()


func play_intro() -> void:
	mode.player_can_wind = false
	if rung == ClockRungs.FIRST_RUNG_WITH_THE_MINUTE_HAND:
		await play_minute_hand_intro()
	else:
		await play_single_minutes_intro()
	mode.clock_face.clear_lit_minutes()


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
	show_set_card_text()


func show_set_card_text() -> void:
	mode.task_banner.show_text(set_card_words(target_minutes))


## "Bath time - make it half past 6": the moment, then the time.
static func set_card_words(time: int) -> String:
	return "%s - make it %s" % [DayMoments.moment_at(time)["name"], ClockTime.time_words(time)]


func play_read_card() -> void:
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
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
		State.CHOOSING:
			if Input.is_action_just_pressed("move_left"):
				mode.answer_cards.move_choice(-1)
			elif Input.is_action_just_pressed("move_right"):
				mode.answer_cards.move_choice(1)
			elif Input.is_action_just_pressed("act"):
				choose_answer()


func confirm_set_time() -> void:
	var made: int = mode.minutes_of_the_day()
	mode.house.show_moment(made)
	if ClockTime.faces_match(made, target_minutes):
		finish_card()
		return
	misses += 1
	Sound.play("plop", 0.02, 0.8)
	show_message_then_the_card(what_was_made(made, target_minutes), set_card_words(target_minutes))
	if misses >= MISSES_BEFORE_THE_GLOW:
		glow_the_target()


## "That's bath time!" - or, when it's the same moment as the one wanted,
## the time itself: "That's half past 6!"
static func what_was_made(made: int, wanted: int) -> String:
	var made_moment: Dictionary = DayMoments.moment_at(made)
	if made_moment["name"] == DayMoments.moment_at(wanted)["name"]:
		return "That's %s!" % ClockTime.time_words(made)
	return made_moment["that_is"]


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
	mode.house.show_moment(picked)
	if picked == target_minutes:
		mode.answer_cards.hide_answers()
		finish_card()
		return
	state = State.SHOWING_A_MISTAKE
	misses += 1
	mode.answer_cards.fade_chosen()
	var this_card: ClockCard = current_card
	var minutes_to_the_picked_time: int = shortest_way_round(target_minutes, picked)
	await mode.wind_itself_by(minutes_to_the_picked_time, SECONDS_TO_WIND_TO_A_PICKED_TIME)
	if this_card != current_card:
		return
	mode.task_banner.show_text("That's %s." % ClockTime.time_words(picked))
	await get_tree().create_timer(SECONDS_ON_A_PICKED_TIME).timeout
	if this_card != current_card:
		return
	await mode.wind_itself_by(-minutes_to_the_picked_time, SECONDS_TO_WIND_TO_A_PICKED_TIME)
	if this_card != current_card:
		return
	mode.house.show_moment(target_minutes)
	mode.task_banner.show_text("What time is it?")
	state = State.CHOOSING


## Minutes from one time to another, forwards or backwards, whichever is shorter.
static func shortest_way_round(from_time: int, to_time: int) -> int:
	var half_a_day: int = ClockTime.MINUTES_IN_HALF_A_DAY
	return posmod(to_time - from_time + half_a_day, ClockTime.MINUTES_IN_A_DAY) - half_a_day


func finish_card() -> void:
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
	Sound.play("chime")
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
