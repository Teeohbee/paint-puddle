extends GameSuite
# Tracing mode's scene: one big dotted letter, painted by driving along it in order, then the next letter.

func open_tracing(letter_index: int = 0) -> TracingMode:
	TracingMode.letter_to_play = letter_index
	get_tree().change_scene_to_file("res://tracing/tracing_mode.tscn")
	await frames(3)
	return get_tree().current_scene

# Drives straight onto each dot in turn, a frame at a time, like a perfect player
func trace_it(mode: TracingMode) -> void:
	for stroke in mode.progress.strokes.duplicate():
		for dot in stroke:
			mode.blob.position = dot
			await frames(1)

func test_it_opens_on_m_with_its_rhyme() -> void:
	var mode := await open_tracing()
	check(mode.letter == "m", "the first letter is m, not %s" % mode.letter)
	check(mode.rhyme_card.rhyme == "Maisie, mountain, mountain", "the card shows m's rhyme")
	check(mode.progress.painted_count() == 0, "nothing is painted yet")

func test_the_blob_starts_away_from_the_letter() -> void:
	var mode := await open_tracing()
	var start: Vector2 = mode.progress.next_dot()
	check(mode.blob.position.distance_to(start) > 400.0, "the blob starts well away from the start dot")
	check(not TracingLetters.PLAY_AREA.has_point(mode.blob.position), "and off the letter's area")

func test_there_is_nothing_to_pull_the_blob_in() -> void:
	await open_tracing()
	check(get_tree().get_nodes_in_group("magnets").is_empty(), "no magnets: stopping is up to the player")

func test_it_opens_on_the_chosen_letter() -> void:
	var mode := await open_tracing(4)
	check(mode.letter == "t", "letter 5 is t, not %s" % mode.letter)

func test_driving_near_the_start_dot_paints_it() -> void:
	var mode := await open_tracing()
	mode.blob.position = mode.progress.next_dot() + Vector2(30, 0)
	await frames(2)
	check(mode.progress.painted_count() > 0, "within reach of the start dot paints it")

func test_tracing_a_letter_saves_it_and_moves_on() -> void:
	var mode := await open_tracing()
	await trace_it(mode)
	check(mode.progress.is_finished(), "every dot painted finishes m")
	check(GameSettings.get_progress("letters_traced") == 1, "finishing m opens a")
	check(TracingMode.letter_just_finished == 0, "and says m was just finished")
	await frames(int(TracingMode.SECONDS_TO_CHEER * 60) + 10)
	check(mode.letter == "a", "after the cheer comes a, not %s" % mode.letter)
	check(mode.progress.painted_count() == 0, "with nothing painted")

func test_tracing_an_earlier_letter_again_keeps_progress() -> void:
	GameSettings.record_progress("letters_traced", 5)
	var mode := await open_tracing(1)
	await trace_it(mode)
	check(GameSettings.get_progress("letters_traced") == 5, "tracing a again doesn't move progress back")

func test_after_the_last_letter_it_goes_back_to_the_menu() -> void:
	var mode := await open_tracing(TracingLetters.ORDER.length() - 1)
	await trace_it(mode)
	check(GameSettings.get_progress("letters_traced") == 0, "q isn't the climbing letter here, so nothing is saved")
	await frames(int(TracingMode.SECONDS_TO_CHEER * 60) + 10)
	check(SceneManager.is_changing_scene or get_tree().current_scene != mode, "after q, it leaves for the menu")

func test_no_letter_is_painted_green_on_the_green_grass() -> void:
	var mode := await open_tracing()
	for index in TracingLetters.ORDER.length():
		mode.start_letter(index)
		check(mode.blob.paint_name != "green", "%s isn't green" % mode.letter)
