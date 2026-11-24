extends GameSuite
# Moving up a Clock rung takes real understanding: 5 cards right first time in a row, on two
# different days. A miss, or a card answered after help, breaks the run. The run and the day carry
# over between sessions, and a version 2 save (from before the rework) starts the Clock again.

const ClockMasteryScript = preload("res://clock/clock_mastery.gd")

func mastery():
	return ClockMasteryScript.new()

## Records answers on a day, returns whether any of them cleared the rung.
func answer(tracker, day: int, first_tries: Array) -> bool:
	var cleared := false
	for first_try in first_tries:
		cleared = tracker.record_answer(first_try, day) or cleared
	return cleared

func test_five_first_tries_on_one_day_are_not_enough() -> void:
	var tracker = mastery()
	check(not answer(tracker, 20261201, [true, true, true, true, true]), "5 in a row on one day doesn't clear")
	check(tracker.run_day == 20261201, "but the day is noted")
	check(not answer(tracker, 20261201, [true, true, true, true, true, true]), "more on the same day still doesn't")

func test_a_second_run_of_five_on_another_day_clears_the_rung() -> void:
	var tracker = mastery()
	answer(tracker, 20261201, [true, true, true, true, true])
	check(not answer(tracker, 20261202, [true, true, true, true]), "4 on the next day isn't enough")
	check(answer(tracker, 20261202, [true]), "the 5th on the next day clears it")

func test_a_miss_breaks_the_run() -> void:
	var tracker = mastery()
	answer(tracker, 20261201, [true, true, true, true, false])
	check(tracker.first_try_run == 0 and tracker.run_day == 0, "a miss at 4 starts again: run %d day %d" % [tracker.first_try_run, tracker.run_day])
	answer(tracker, 20261201, [true, true, true, true, true])
	answer(tracker, 20261203, [true, true, false])
	check(tracker.run_day == 20261201, "a miss on day two keeps day one's run")
	check(answer(tracker, 20261203, [true, true, true, true, true]), "and five more that day clear it")

func test_a_run_started_on_day_one_only_counts_answers_from_a_later_day() -> void:
	var tracker = mastery()
	answer(tracker, 20261201, [true, true, true, true, true, true, true])
	check(tracker.first_try_run == 0, "after day one's run, the same day's answers don't build a new run: %d" % tracker.first_try_run)

func test_the_run_and_day_are_saved_and_carry_over() -> void:
	var tracker = mastery()
	answer(tracker, 20261201, [true, true, true, true, true])
	answer(tracker, 20261202, [true, true])
	tracker.save()
	GameSettings.load_from_disk()
	var reloaded = ClockMasteryScript.load_saved()
	check(reloaded.first_try_run == 2 and reloaded.run_day == 20261201, "run 2, day one kept: %d %d" % [reloaded.first_try_run, reloaded.run_day])
	check(answer(reloaded, 20261202, [true, true, true]), "three more clear it")

func test_today_is_the_machines_date_as_a_number() -> void:
	var today: Dictionary = Time.get_date_dict_from_system()
	check(ClockMasteryScript.today() == today.year * 10000 + today.month * 100 + today.day, "yyyymmdd: %d" % ClockMasteryScript.today())

func write_save(contents: Dictionary) -> void:
	var file := FileAccess.open(GameSettings.save_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(contents))
	file.close()

func test_a_version_2_save_starts_the_clock_again_and_leaves_the_rest() -> void:
	write_save({"version": 2, "progress": {"clock_rungs_cleared": 5, "hills_levels_completed": 12, "letters_traced": 7},
		"clock_task_deck": [841, 1080]})
	GameSettings.load_from_disk()
	check(GameSettings.get_progress("clock_rungs_cleared") == 0, "Clock back to rung 1")
	check(GameSettings.get_clock_task_deck().is_empty(), "no Clock deck")
	check(GameSettings.get_progress("hills_levels_completed") == 12 and GameSettings.get_progress("letters_traced") == 7, "Hills and Write untouched")

func test_a_version_3_save_keeps_its_clock() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 1)
	GameSettings.record_progress("clock_first_try_run", 3)
	GameSettings.record_progress("clock_run_day", 20261201)
	GameSettings.load_from_disk()
	check(GameSettings.get_progress("clock_rungs_cleared") == 1, "rung kept")
	check(GameSettings.get_progress("clock_first_try_run") == 3 and GameSettings.get_progress("clock_run_day") == 20261201, "run kept")

func test_resetting_the_clock_clears_the_run_too() -> void:
	GameSettings.record_progress("clock_first_try_run", 3)
	GameSettings.record_progress("clock_run_day", 20261201)
	GameSettings.record_progress("clock_rung_intros_seen", 1)
	GameSettings.reset_part("clock")
	for progress_name in ["clock_first_try_run", "clock_run_day", "clock_rung_intros_seen"]:
		check(GameSettings.get_progress(progress_name) == 0, progress_name + " cleared")
