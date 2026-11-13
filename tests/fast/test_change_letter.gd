extends GameSuite
# Change one letter: the old word's thing is in the meadow, pick the new
# letter and it turns into the new word's thing.

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

func open_meadow_on_task(task_index):
	GameSettings.record_progress("next_task_index", task_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	await get_tree().create_timer(1.2).timeout

func test_change_letter() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	var MeadowTaskClass = load("res://core/meadow_task.gd")
	var dog_to_log = MeadowTaskClass.from_dictionary({"type": "change", "from": "DOG", "word": "LOG", "thing": "log", "text": "?"})
	check(dog_to_log != null and dog_to_log.changed_letter_index() == 0, "DOG to LOG changes the first letter")
	var stones = dog_to_log.stone_values()
	check(stones.size() == 4 and stones.has("L") and stones.has("D"), "four stones: L, the old D and two others: %s" % [stones])
	check(stones == dog_to_log.fresh_copy().stone_values(), "the same stones every time")
	check(dog_to_log.handle({"kind": "stone", "value": "D"}) == "wrong", "D makes DOG again - wrong")
	check(dog_to_log.handle({"kind": "stone", "value": "L"}) == "done", "L makes LOG")
	check(MeadowTaskClass.from_dictionary({"type": "change", "from": "DOG", "word": "LOT", "thing": "log", "text": "?"}) == null, "two letters changed is skipped")
	check(MeadowTaskClass.from_dictionary({"type": "change", "from": "DOG", "word": "DOGS", "thing": "dog", "text": "?"}) == null, "different lengths are skipped")
	check(MeadowTaskClass.from_dictionary({"type": "change", "from": "DOG", "word": "DIG", "thing": "dig", "text": "?"}) == null, "a word with no picture is skipped")

	# Find the DOG -> LOG task in the pack
	var tasks = MeadowTaskClass.load_list("res://data/tasks.json")
	var task_index = -1
	for index in tasks.size():
		if tasks[index].type == "change" and tasks[index].word == "LOG":
			task_index = index
	check(task_index > 43, "DOG to LOG is in the new tasks")
	await open_meadow_on_task(task_index)
	var dog = meadow.spelled_things.find_staying("dog")
	check(dog != null, "the dog is waiting in the meadow to be changed")
	check(not settings.has_found("words_spelled", "dog"), "being shown a dog doesn't put it in the book")
	check(dog.position.distance_to(blob.position) > 200, "it isn't on top of the blob")
	await visit(stone_with("D").position)
	check(not meadow.task_runner.is_between_tasks, "D is wrong")
	await visit(stone_with("L").position)
	await get_tree().process_frame
	check(meadow.task_runner.is_between_tasks, "L finishes it")
	check(meadow.spelled_things.find_staying("dog") == null, "the dog has gone")
	var log_thing = meadow.spelled_things.find_staying("log")
	check(log_thing != null, "and a log is in its place")
	check(settings.has_found("words_spelled", "log"), "the log goes in the book")
	check(meadow.spelled_things.things_staying().size() == 1, "just the log")

	# The book now has the new words too
	var book_script = load("res://ui/book.gd")
	var words = book_script.words_in_the_book()
	check(words.has("log") and words.has("bell") and words.size() == 42, "the book lists all 42 things: %d" % words.size())

