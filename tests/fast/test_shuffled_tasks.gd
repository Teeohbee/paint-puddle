extends GameSuite
# Meadow tasks come in a shuffled order, dealt like a deck: every task once
# before any comes round again. The deck is saved, so quitting doesn't reset it.

func fresh_settings(path):
	var settings = auto_free(load("res://core/game_settings.gd").new())
	settings.save_file_path = path
	settings.load_from_disk()
	return settings

func write_save(path, contents):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(contents))
	file.close()

func test_shuffled_tasks() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().create_timer(0.5).timeout
	var runner = get_tree().current_scene.task_runner
	var task_count = runner.tasks.size()

	# The two teaching tasks
	var Task = load("res://core/meadow_task.gd")
	var all_tasks = Task.load_list("res://data/tasks.json")
	check(all_tasks[0].type == "make" and all_tasks[0].paint == "red", "task 0 is the red paint")
	check(all_tasks[1].type == "visit" and all_tasks[1].target == "fountain", "task 1 is the wash")
	check(settings.get_progress("next_task_index") == 0, "a new game starts on the red paint")
	check(runner.deal_next_task_index(0) == 1, "and the wash comes next")

	# A whole round, starting after the wash
	var current = 1
	var dealt = []
	var in_order = 0
	for round_step in task_count - 2:
		var next = runner.deal_next_task_index(current)
		if next == current + 1:
			in_order += 1
		dealt.append(next)
		current = next
	var unique = {}
	for index in dealt:
		unique[index] = true
	check(unique.size() == task_count - 2, "the first round deals every other task once: %d of %d" % [unique.size(), task_count - 2])
	check(not unique.has(0) and not unique.has(1), "and not the two teaching tasks again")
	check(dealt.all(func(index): return index >= 0 and index < task_count), "every dealt task is real")
	check(in_order < task_count / 4, "the order is mixed up, not 1, 2, 3: %d in order" % in_order)

	# The next round starts fresh, without repeating the task just played
	var last_of_round = current
	if last_of_round == 0:
		last_of_round = runner.deal_next_task_index(0)
	var first_of_next = runner.deal_next_task_index(last_of_round)
	check(first_of_next != last_of_round and first_of_next != 1, "a new round never repeats the task just played, nor starts with the wash")
	check(settings.get_task_deck().size() == task_count - 3, "the new round's deck is the rest of the tasks, less the wash")

	# Rounds differ
	var second_round = [first_of_next]
	for round_step in 10:
		second_round.append(runner.deal_next_task_index(second_round[-1]))
	check(second_round != dealt.slice(0, 11), "the second round is shuffled differently")
	var rest_of_second_round = second_round.duplicate()
	while settings.get_task_deck().size() > 0 or rest_of_second_round[-1] == 0:
		rest_of_second_round.append(runner.deal_next_task_index(rest_of_second_round[-1]))
	var red_at = rest_of_second_round.find(0)
	check(red_at >= 0 and rest_of_second_round[red_at + 1] == 1, "in later rounds the red paint comes back, with the wash straight after")

	# Saved
	var deck_before = settings.get_task_deck()
	var reloaded = fresh_settings(settings.save_file_path)
	check(reloaded.get_task_deck() == deck_before, "the deck is saved")
	reloaded.reset_progress()
	check(reloaded.get_task_deck().is_empty(), "resetting progress empties the deck")

	# A broken or old deck in the save is cleaned up
	var path = "user://shuffled_tasks_check_old.json"
	write_save(path, {"version": 2, "progress": {"next_task_index": 3}})
	check(fresh_settings(path).get_task_deck().is_empty(), "a save from before the deck has an empty one")
	write_save(path, {"version": 2, "task_deck": [5, "seven", -2, 5, 9.0, 99999]})
	check(fresh_settings(path).get_task_deck() == [5, 9, 99999], "only whole, non-negative numbers, each once")
	settings.set_task_deck(Array([99999, 3], TYPE_INT, "", null))
	var after_stale = runner.deal_next_task_index(7)
	check(after_stale == 3, "tasks that no longer exist are skipped: got %d" % after_stale)
	settings.set_task_deck(Array([3], TYPE_INT, "", null))
	check(runner.deal_next_task_index(3) != 3, "the task just played is never dealt again straight away")
	settings.set_task_deck(Array([1], TYPE_INT, "", null))
	check(runner.deal_next_task_index(7) != 1, "the wash is never dealt on its own")
	settings.set_task_deck(Array([], TYPE_INT, "", null))
	check(runner.deal_next_task_index(1) != 0, "after the wash, a new deck doesn't start with the red paint again")

