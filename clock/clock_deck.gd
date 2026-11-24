class_name ClockDeck
extends RefCounted
## Deals a rung's cards, and the three answers on a read card. Takes the
## random number generator from the caller, so tests can seed it.

const CARDS_IN_A_DECK: int = 8
## Read or set, card by card: it opens on reading (setting is harder), and
## set cards take over to about half and half by the end.
const READ_OR_SET_ORDER: Array[bool] = [true, true, true, false, true, false, true, false]
## On rung 7, "10 to" and "5 to" come last: by then the hour hand has crept
## right up to the next number, which is the real test.
const LATE_MINUTES_RUNG: int = 7
const FIRST_LATE_MINUTE: int = 45


static func deal(rung: int, random: RandomNumberGenerator) -> Array[ClockCard]:
	var times: Array[int] = ClockRungs.times_of_the_day(rung)
	shuffle(times, random)
	var chosen_times: Array[int] = []
	chosen_times.assign(times.slice(0, CARDS_IN_A_DECK))
	if rung == LATE_MINUTES_RUNG:
		chosen_times = early_minutes_first(chosen_times)
	var deck: Array[ClockCard] = []
	for index in chosen_times.size():
		deck.append(ClockCard.new(READ_OR_SET_ORDER[index], chosen_times[index]))
	return deck


static func early_minutes_first(times: Array[int]) -> Array[int]:
	var early: Array[int] = []
	var late: Array[int] = []
	for time in times:
		if time % ClockTime.MINUTES_IN_AN_HOUR >= FIRST_LATE_MINUTE:
			late.append(time)
		else:
			early.append(time)
	return early + late


## The three answers on a read card, in a shuffled order: the right time and
## two classic mistakes. Answers are just words, so no two may read the same
## on the face (9 in the morning and 9 at night would both say "9 o'clock").
static func read_answers(rung: int, time: int, random: RandomNumberGenerator) -> Array[int]:
	var answers: Array[int] = [time]
	for mistake in likely_mistakes(rung, time, random):
		if answers.size() == 3:
			break
		if answers.any(func(answer: int) -> bool: return ClockTime.faces_match(answer, mistake)):
			continue
		answers.append(mistake)
	shuffle(answers, random)
	return answers


## Mistakes a child really makes, most likely first. There are always
## enough that two of them are new.
static func likely_mistakes(rung: int, time: int, random: RandomNumberGenerator) -> Array[int]:
	var mistakes: Array[int] = [hour_hand_mistake(time, random)]
	var hands_swapped: int = hands_swapped_mistake(rung, time)
	if rung == ClockRungs.SINGLE_MINUTES_RUNG:
		# counting the minutes from the wrong side of a five
		mistakes.append(ClockTime.wound(time, 5 if random.randi() % 2 == 0 else -5))
	elif hands_swapped != time and random.randi() % 3 != 0:
		mistakes.append(hands_swapped)
	mistakes.append(hands_swapped)
	mistakes.append(ClockTime.wound(time, ClockTime.MINUTES_IN_AN_HOUR * 2))
	mistakes.append(ClockTime.wound(time, -ClockTime.MINUTES_IN_AN_HOUR * 2))
	return mistakes


## Reading the hour from the number the hour hand is nearest or just
## passed, when it's really between two. Up to half past it sits near the
## next number ("half past 4" for half past 3); after half past it's still
## just past this hour's number ("quarter to 3" for quarter to 4).
static func hour_hand_mistake(time: int, random: RandomNumberGenerator) -> int:
	var minute: int = time % ClockTime.MINUTES_IN_AN_HOUR
	if minute == 0:
		var one_hour_either_way: int = ClockTime.MINUTES_IN_AN_HOUR if random.randi() % 2 == 0 else -ClockTime.MINUTES_IN_AN_HOUR
		return ClockTime.wound(time, one_hour_either_way)
	if minute <= 30:
		return ClockTime.wound(time, ClockTime.MINUTES_IN_AN_HOUR)
	return ClockTime.wound(time, -ClockTime.MINUTES_IN_AN_HOUR)


## Reading the minute hand as the hour and the hour hand as the minutes,
## rounded to the rung's step, in the same half of the day. Without a
## minute hand there's nothing to mix up, so it's the time itself.
@warning_ignore("integer_division")
static func hands_swapped_mistake(rung: int, time: int) -> int:
	if not ClockRungs.shows_minute_hand(rung):
		return time
	var minute_hand_number: int = (time % ClockTime.MINUTES_IN_AN_HOUR) / 5
	var hour_hand_as_minutes: float = ClockTime.hour_hand_turns(time) * ClockTime.MINUTES_IN_AN_HOUR
	var step: int = ClockRungs.step_minutes(rung)
	var swapped_minute: int = roundi(hour_hand_as_minutes / step) * step % ClockTime.MINUTES_IN_AN_HOUR
	var start_of_this_half: int = time - time % ClockTime.MINUTES_IN_HALF_A_DAY
	return start_of_this_half + (minute_hand_number % 12) * ClockTime.MINUTES_IN_AN_HOUR + swapped_minute


## Fisher-Yates with the given generator, so a seed always gives the same order.
static func shuffle(values: Array, random: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other_index: int = random.randi_range(0, index)
		var kept: Variant = values[index]
		values[index] = values[other_index]
		values[other_index] = kept
