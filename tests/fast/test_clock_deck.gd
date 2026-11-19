extends GdUnitTestSuite
# ClockDeck: dealing a rung's cards, and the wrong answers on a read card.

const EVERY_RUNG: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]

func seeded(seed_value: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	return random

func minutes_of(hour_of_the_day: int, minute: int) -> int:
	return hour_of_the_day * 60 + minute


# ---- dealing

func test_a_deck_is_eight_cards_of_the_rungs_own_times() -> void:
	for rung in EVERY_RUNG:
		for seed_value in 20:
			var deck: Array[ClockCard] = ClockDeck.deal(rung, seeded(seed_value))
			assert_int(deck.size()).is_equal(ClockDeck.CARDS_IN_A_DECK)
			for card in deck:
				assert_bool(ClockRungs.times_of_the_day(rung).has(card.minutes_of_the_day)).override_failure_message(
					"rung %d dealt %s" % [rung, ClockTime.digital_text(card.minutes_of_the_day)]).is_true()

func test_no_time_comes_up_twice_in_a_deck() -> void:
	for rung in EVERY_RUNG:
		var deck: Array[ClockCard] = ClockDeck.deal(rung, seeded(rung))
		var times: Dictionary = {}
		for card in deck:
			times[card.minutes_of_the_day] = true
		assert_int(times.size()).is_equal(deck.size())

func test_a_deck_opens_on_reading_and_ends_about_half_and_half() -> void:
	for seed_value in 20:
		var deck: Array[ClockCard] = ClockDeck.deal(3, seeded(seed_value))
		assert_bool(deck[0].is_read).override_failure_message("a deck never opens on a set card").is_true()
		assert_bool(deck[1].is_read).is_true()
		var sets_in_the_second_half: int = 0
		for card in deck.slice(4):
			if not card.is_read:
				sets_in_the_second_half += 1
		assert_int(sets_in_the_second_half).is_between(2, 3)

func test_rung_7_saves_the_last_minutes_of_the_hour_for_the_end() -> void:
	for seed_value in 20:
		var deck: Array[ClockCard] = ClockDeck.deal(7, seeded(seed_value))
		var seen_a_late_minute: bool = false
		for card in deck:
			var is_late: bool = card.minutes_of_the_day % 60 >= 45
			assert_bool(seen_a_late_minute and not is_late).override_failure_message(
				"5 to and 10 to come after 25 to and 20 to").is_false()
			seen_a_late_minute = seen_a_late_minute or is_late

func test_the_same_seed_deals_the_same_deck() -> void:
	var first: Array[ClockCard] = ClockDeck.deal(6, seeded(7))
	var second: Array[ClockCard] = ClockDeck.deal(6, seeded(7))
	for index in first.size():
		assert_int(first[index].minutes_of_the_day).is_equal(second[index].minutes_of_the_day)


# ---- saving

func test_a_card_saves_as_one_whole_number_and_comes_back() -> void:
	var read_card := ClockCard.new(true, minutes_of(15, 40))
	var set_card := ClockCard.new(false, minutes_of(15, 40))
	assert_int(read_card.saved_number()).is_not_equal(set_card.saved_number())
	var read_again: ClockCard = ClockCard.from_saved_number(read_card.saved_number())
	assert_bool(read_again.is_read).is_true()
	assert_int(read_again.minutes_of_the_day).is_equal(minutes_of(15, 40))
	assert_bool(ClockCard.from_saved_number(set_card.saved_number()).is_read).is_false()


# ---- wrong answers on a read card

func assert_good_answers(rung: int, time: int, seed_value: int) -> void:
	var answers: Array[int] = ClockDeck.read_answers(rung, time, seeded(seed_value))
	var label: String = "rung %d at %s" % [rung, ClockTime.digital_text(time)]
	assert_int(answers.size()).override_failure_message(label).is_equal(3)
	assert_bool(answers.has(time)).override_failure_message("%s: the right answer is there" % label).is_true()
	var unique: Dictionary = {}
	var wrong_halves: int = 0
	for answer in answers:
		unique[answer] = true
		if answer != time and answer % ClockTime.MINUTES_IN_HALF_A_DAY == time % ClockTime.MINUTES_IN_HALF_A_DAY:
			wrong_halves += 1
	assert_int(unique.size()).override_failure_message("%s: three different answers %s" % [label, answers]).is_equal(3)
	assert_int(wrong_halves).override_failure_message("%s: at most one wrong half" % label).is_less_equal(1)

func test_every_read_card_has_three_different_answers_one_right() -> void:
	for rung in EVERY_RUNG:
		for time in ClockRungs.times_of_the_day(rung):
			assert_good_answers(rung, time, time)

func test_the_hour_hand_between_numbers_mistake_is_offered() -> void:
	# half past 3: the hour hand is halfway to the 4, so "half past 4" is the classic slip
	var answers: Array[int] = ClockDeck.read_answers(3, minutes_of(15, 30), seeded(1))
	assert_array(answers).contains([minutes_of(16, 30)])
	# quarter to 4: the hour hand is still just past the 3, so "quarter to 3"
	answers = ClockDeck.read_answers(5, minutes_of(15, 45), seeded(1))
	assert_array(answers).contains([minutes_of(14, 45)])

func test_hands_mixed_up_is_offered_when_both_hands_show() -> void:
	# 6:00 with the hands swapped: the minute hand on 12 read as the hour, the hour hand on 6 as half past
	var offered_swap: bool = false
	for seed_value in 10:
		var answers: Array[int] = ClockDeck.read_answers(3, minutes_of(6, 0), seeded(seed_value))
		offered_swap = offered_swap or answers.has(minutes_of(0, 30))
	assert_bool(offered_swap).is_true()

func test_answers_come_in_a_shuffled_order() -> void:
	var places_of_the_right_answer: Dictionary = {}
	for seed_value in 30:
		var answers: Array[int] = ClockDeck.read_answers(3, minutes_of(9, 0), seeded(seed_value))
		places_of_the_right_answer[answers.find(minutes_of(9, 0))] = true
	assert_int(places_of_the_right_answer.size()).is_equal(3)
