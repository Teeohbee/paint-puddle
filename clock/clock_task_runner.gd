class_name ClockTaskRunner
extends Node
## Plays a deck of Clock mode cards, one at a time.
##
## A set card gives a time; the player winds the hands and presses A. A
## wrong time isn't wrong: the card says what time he made, then asks again,
## and after a second miss the number to aim for glows.
##
## A read card winds the clock itself to a time, then offers three answers
## under the clock. A wrong pick winds the hands to the time he picked, shows
## it, winds back, and that card fades away so he can't go round in circles.

signal card_finished(card: ClockCard)
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

var mode: ClockMode
var rung: int = 1
var deck: Array[ClockCard] = []
var card_index: int = 0
var current_card: ClockCard
var misses: int = 0
var state: State = State.BETWEEN_CARDS
var random: RandomNumberGenerator = RandomNumberGenerator.new()
## Counts messages, so an old message's timer doesn't put back a card that has moved on.
var messages_shown: int = 0


func _init(clock_mode: ClockMode) -> void:
	mode = clock_mode
	random.randomize()


## Every deck starts at 7 in the morning, and the day carries on from card to card.
func start_deck(new_rung: int, new_deck: Array[ClockCard]) -> void:
	rung = new_rung
	deck = new_deck
	card_index = 0
	mode.show_rung(rung)
	mode.answer_cards.hide_answers()
	mode.start_the_day()
	play_card()


func play_card() -> void:
	current_card = deck[card_index]
	misses = 0
	if current_card.is_read:
		play_read_card()
	else:
		play_set_card()


func play_set_card() -> void:
	state = State.SETTING
	mode.player_can_wind = true
	show_set_card_text()


func show_set_card_text() -> void:
	mode.task_banner.show_text("Make it %s" % ClockTime.time_in_the_day_words(current_card.minutes_of_the_day), small_line(current_card.minutes_of_the_day))


## am/pm, and the digital time on the rungs that show it.
func small_line(time: int) -> String:
	var line: String = ClockTime.am_or_pm(time)
	if ClockRungs.shows_digital_helper(rung):
		line += " · " + ClockTime.digital_text(time)
	return line


func play_read_card() -> void:
	state = State.BETWEEN_CARDS
	mode.player_can_wind = false
	mode.task_banner.show_text("What time is it?")
	var this_card: ClockCard = current_card
	var minutes_forward: int = posmod(current_card.minutes_of_the_day - mode.minutes_of_the_day(), ClockTime.MINUTES_IN_A_DAY)
	await mode.wind_itself_by(minutes_forward, SECONDS_TO_WIND_TO_A_READ_TIME)
	if this_card != current_card:
		return
	var answers: Array[int] = ClockDeck.read_answers(rung, current_card.minutes_of_the_day, random)
	mode.answer_cards.show_answers(answers, ClockRungs.shows_digital_helper(rung))
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
	if mode.minutes_of_the_day() == current_card.minutes_of_the_day:
		finish_card()
		return
	misses += 1
	Sound.play("move", 0.02, 0.7)
	var made: String = ClockTime.time_in_the_day_words(mode.minutes_of_the_day())
	var wanted: String = ClockTime.time_in_the_day_words(current_card.minutes_of_the_day)
	show_message_then_the_card("That's %s!" % made, "Make it %s" % wanted)
	if misses >= MISSES_BEFORE_THE_GLOW:
		glow_the_target()


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
	var time: int = current_card.minutes_of_the_day
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
	if picked == current_card.minutes_of_the_day:
		mode.answer_cards.hide_answers()
		finish_card()
		return
	state = State.SHOWING_A_MISTAKE
	misses += 1
	mode.answer_cards.fade_chosen()
	var this_card: ClockCard = current_card
	var minutes_to_the_picked_time: int = shortest_way_round(current_card.minutes_of_the_day, picked)
	await mode.wind_itself_by(minutes_to_the_picked_time, SECONDS_TO_WIND_TO_A_PICKED_TIME)
	if this_card != current_card:
		return
	mode.task_banner.show_text("That's %s." % ClockTime.time_in_the_day_words(picked))
	await get_tree().create_timer(SECONDS_ON_A_PICKED_TIME).timeout
	if this_card != current_card:
		return
	await mode.wind_itself_by(-minutes_to_the_picked_time, SECONDS_TO_WIND_TO_A_PICKED_TIME)
	if this_card != current_card:
		return
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
	mode.task_banner.show_text("Yes! It's %s" % ClockTime.time_in_the_day_words(current_card.minutes_of_the_day))
	var finished: ClockCard = current_card
	card_finished.emit(finished)
	await get_tree().create_timer(SECONDS_TO_CELEBRATE).timeout
	if finished != current_card:
		return
	card_index += 1
	if card_index >= deck.size():
		deck_finished.emit()
		return
	play_card()
