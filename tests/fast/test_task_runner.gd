extends GameSuite

var meadow
var blob

func visit(target_position):
	blob.position = Vector2(960, 740)
	await get_tree().physics_frame
	await get_tree().physics_frame
	blob.position = target_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

func things_in_grass(kind):
	var found = []
	for thing in meadow.get_node("StonesAndDrops").get_children():
		if is_instance_of(thing, kind) and not thing.is_leaving:
			found.append(thing)
	return found

func stone_with(value):
	for stone in things_in_grass(LetterStone):
		if stone.value == value:
			return stone

func open_meadow_on_task(task_index):
	var settings = GameSettings
	settings.record_progress("next_task_index", task_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	await get_tree().create_timer(1.2).timeout

func test_task_runner() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	await open_meadow_on_task(2)
	var runner = meadow.task_runner
	check(runner.current_task.word == "RED", "task 3 is spelling RED")
	check(things_in_grass(LetterStone).size() == 3, "three letter stones in the grass")
	await visit(stone_with("E").position)
	check(runner.current_task.letters_done == 0 and stone_with("E") != null, "E first just wobbles and stays")
	await visit(stone_with("R").position)
	await visit(stone_with("E").position)
	check(runner.current_task.letters_done == 2, "R then E spells two letters")
	settings.set_task_deck(Array([3], TYPE_INT, "", null))
	var completed_before = settings.get_progress("tasks_completed")
	await visit(stone_with("D").position)
	check(runner.is_between_tasks, "D finishes the word")
	check(settings.get_progress("tasks_completed") == completed_before + 1, "the finished task is counted")
	check(settings.get_progress("next_task_index") == 3, "and the next task dealt is remembered")
	await get_tree().create_timer(3.5).timeout
	check(runner.current_task.type == "make" and runner.current_task.paint == "orange", "the next card is making orange")
	check(things_in_grass(LetterStone).is_empty(), "the old stones are gone")
	await visit(meadow.fountain.position)
	await visit(meadow.puddles["red"].position)
	await visit(meadow.puddles["yellow"].position)
	check(runner.is_between_tasks, "mixing orange finishes it")

	await open_meadow_on_task(4)
	runner = meadow.task_runner
	var drops = things_in_grass(PaintDrop)
	check(drops.size() == 5, "collect 3 yellow puts out 3 yellow and 2 red drops")
	for drop in drops:
		if drop.paint_name == "red":
			await visit(drop.position)
			break
	check(runner.current_task.collected == 0, "a red drop doesn't count")
	for drop in drops:
		if drop.paint_name == "yellow":
			await visit(drop.position)
	check(runner.is_between_tasks and runner.current_task.collected == 3, "three yellow drops finish it")

	await open_meadow_on_task(5)
	runner = meadow.task_runner
	check(things_in_grass(LetterStone).size() == 3, "2 + 1 puts out three number stones")
	await visit(stone_with("4").position)
	check(not runner.is_between_tasks, "4 is wrong")
	await visit(stone_with("3").position)
	check(runner.is_between_tasks, "3 is right")

	settings.record_progress("next_task_index", 13)
	await open_meadow_on_task(13)
	check(meadow.task_runner.current_task.type == "rainbow", "task 13 is a rainbow")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://task_runner_check.json"))
