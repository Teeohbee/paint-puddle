extends GameSuite
# Picture clues: the banner shows the thing, not the word.

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

func stone_with(value):
	for stone in meadow.get_node("StonesAndDrops").get_children():
		if stone is LetterStone and stone.value == value and not stone.is_leaving:
			return stone

func test_picture_clues() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var Task = load("res://core/meadow_task.gd")
	check(Task.from_dictionary({"type": "spell", "word": "FOX", "clue": true, "text": "?"}) == null, "a clue with no picture is skipped")
	var clue = Task.from_dictionary({"type": "spell", "word": "FOX", "thing": "fox", "clue": true, "text": "What's this? Spell it!"})
	check(clue != null and clue.is_clue, "a picture clue loads")
	check(not clue.text.contains("FOX"), "the clue's sentence doesn't give the word away")

	var tasks = Task.load_list("res://data/tasks.json")
	var clue_tasks = tasks.filter(func(task): return task.is_clue)
	check(clue_tasks.size() >= 10, "the new round has picture clues: %d" % clue_tasks.size())
	check(clue_tasks.all(func(task): return not task.text.contains(task.word)), "no clue says its own word")
	check(tasks.slice(0, 41).all(func(task): return not task.is_clue), "the first round has none")

	# Play a clue task through
	var clue_index = tasks.find(clue_tasks[0])
	settings.record_progress("next_task_index", clue_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().create_timer(1.3).timeout
	meadow = get_tree().current_scene
	blob = meadow.blob
	var word = meadow.task_runner.current_task.word
	check(meadow.task_runner.current_task.is_clue, "the meadow is on a picture clue: " + word)
	for letter_index in word.length():
		await visit(stone_with(word[letter_index]).position)
	await get_tree().process_frame
	check(meadow.task_runner.is_between_tasks, "spelling it finishes the task")
	check(meadow.spelled_things.find_staying(word.to_lower()) != null, "and the thing comes to life")

	# The longest word, with repeated letters, plays through
	var longest = tasks.size() - 1
	check(tasks[longest].word == "CATERPILLAR" and tasks[longest].is_clue, "the last task is the CATERPILLAR clue")
	settings.record_progress("next_task_index", longest)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().create_timer(1.6).timeout
	meadow = get_tree().current_scene
	blob = meadow.blob
	var stones = meadow.get_node("StonesAndDrops").get_children().filter(func(thing): return thing is LetterStone)
	check(stones.size() == 11, "eleven letter stones fit: %d" % stones.size())
	for letter in "CATERPILLAR":
		await visit(stone_with(letter).position)
	await get_tree().process_frame
	check(meadow.task_runner.is_between_tasks, "CATERPILLAR can be spelled, double L and all")
	check(meadow.spelled_things.find_staying("caterpillar") != null, "and a caterpillar comes to life")
