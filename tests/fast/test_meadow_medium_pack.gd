extends GameSuite
# Medium's own cards, data/tasks_medium.json: harder words, mostly without a picture, bigger sums with close
# choices, colour riddles with no recipe, and fewer rainbows, one of them painted in order.

const PACK := "res://data/tasks_medium.json"

func medium() -> Array[MeadowTask]:
	return MeadowTask.load_list(PACK)

func easy() -> Array[MeadowTask]:
	return MeadowTask.load_list(TaskRunner.TASKS_PATH)

func count_of(tasks: Array[MeadowTask], type: String) -> int:
	return tasks.filter(func(task): return task.type == type).size()

func test_every_card_loads() -> void:
	var raw_count: int = JSON.parse_string(FileAccess.get_file_as_string(PACK)).size()
	check(medium().size() == raw_count, "no Medium card is skipped: %d of %d" % [medium().size(), raw_count])
	check(medium().size() >= 30, "a proper pack, not a starter: %d" % medium().size())

func test_no_word_repeats_an_easy_word() -> void:
	var easy_words := {}
	for task in easy():
		easy_words[task.word] = true
		easy_words[task.from_word] = true
	for task in medium():
		check(task.word == "" or not easy_words.has(task.word), "%s is an Easy word" % task.word)

func test_no_word_comes_up_twice() -> void:
	var seen := {}
	for task in medium():
		if task.word != "":
			check(not seen.has(task.word), "%s comes up twice" % task.word)
			seen[task.word] = true

func test_every_word_fits_in_the_grass() -> void:
	for task in medium():
		check(task.stone_values().size() <= MeadowTask.MOST_THINGS_IN_THE_GRASS, "%s has too many stones" % task.word)

func test_most_words_have_no_picture() -> void:
	var spells: Array[MeadowTask] = medium().filter(func(task): return task.type == "spell")
	var with_pictures: int = spells.filter(func(task): return task.thing != "").size()
	check(with_pictures > 0, "a few new pictures as treats")
	check(with_pictures * 4 <= spells.size(), "mostly without: %d of %d" % [with_pictures, spells.size()])

func test_make_cards_are_riddles_without_a_recipe() -> void:
	for task in medium():
		if task.type == "make":
			check(not task.text.to_lower().contains("mix") and not task.text.to_lower().contains(task.paint), "no recipe or answer: " + task.text)

func test_sums_have_close_choices() -> void:
	for task in medium():
		if task.type == "sum":
			var numbers: Array = Array(task.question.split(" ")).filter(func(part): return part.is_valid_int()).map(func(part): return int(part))
			check(numbers.max() >= 10 or task.answer >= 10, "bigger numbers: " + task.question)
			for choice in task.choices:
				check(absi(choice - task.answer) <= 2, "%s: %d is close to %d" % [task.question, choice, task.answer])

func test_fewer_rainbows_one_in_order() -> void:
	check(count_of(medium(), "rainbow") < count_of(easy(), "rainbow"), "fewer rainbow cards than Easy")
	check(medium().any(func(task): return task.type == "rainbow" and task.in_order), "one painted in order")
	check(not easy().any(func(task): return task.in_order), "Easy's rainbows never ask for an order")

func test_every_picture_and_puddle_exists() -> void:
	for task in medium():
		check(task.thing == "" or ThingDrawings.can_draw(task.thing), "no picture of a %s" % task.thing)
		if task.type == "visit" and task.target.begins_with("puddle:"):
			check(["red", "yellow", "blue"].has(task.target.trim_prefix("puddle:")), "no %s in the meadow" % task.target)

func test_the_book_has_medium_pictures_after_easys() -> void:
	var book_words: Array[String] = load("res://ui/book.gd").words_in_the_book()
	check(book_words[0] == "cat", "Easy's first")
	for task in medium():
		if task.thing != "":
			check(book_words.has(task.thing), "the Book has a page for %s" % task.thing)
