extends GameSuite
# Finishing a part of the Book is a big moment: the first time the Book opens
# with every word (or colour) found there's confetti and a chime, once. After
# that the part keeps a gold star and says it's all found.

func open_book():
	get_tree().change_scene_to_file("res://ui/book.tscn")
	await get_tree().create_timer(0.6).timeout
	return get_tree().current_scene

func section_tile(book, word):
	for tile in book.page_holder.find_children("*", "MenuTile", true, false):
		if tile.word == word:
			return tile
	return null

func confetti_in(book):
	return book.find_children("*", "Confetti", true, false).size()

func test_book_complete() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var book_class = load("res://ui/book.gd")
	var all_words = book_class.words_in_the_book()

	for word in all_words.slice(1):
		settings.record_found("words_spelled", word)
	var book = await open_book()
	check(not section_tile(book, "Words").has_gold_star, "one word short: no gold star")
	check(confetti_in(book) == 0, "one word short: no confetti")

	settings.record_found("words_spelled", all_words[0])
	book = await open_book()
	var words_tile = section_tile(book, "Words")
	check(words_tile.has_gold_star, "every word found: Words has a gold star")
	check(words_tile.subtitle == "All %d!" % all_words.size(), "and says All %d!: %s" % [all_words.size(), words_tile.subtitle])
	check(not section_tile(book, "Colours").has_gold_star, "Colours isn't finished, so no star there")
	check(confetti_in(book) == 1, "the first time, confetti")
	check(book.found_label.text == "You found every word!", "and a cheer: " + book.found_label.text)

	settings.load_from_disk()
	book = await open_book()
	check(section_tile(book, "Words").has_gold_star, "the star stays after a restart")
	check(confetti_in(book) == 0, "the confetti only happens once, even after a restart")
	check(book.found_label.text == "", "no cheer the second time")

	book.open_section("words")
	await get_tree().create_timer(0.3).timeout
	check(book.found_label.text == "You found every word!", "inside Words it says they're all found: " + book.found_label.text)

	for paint in book_class.entries_for("colours"):
		settings.record_found("colours_found", paint)
	book = await open_book()
	check(section_tile(book, "Colours").has_gold_star, "every colour found: Colours has a gold star")
	check(confetti_in(book) == 1, "confetti for finishing Colours too")
	check(book.found_label.text == "You found every colour!", "and its own cheer: " + book.found_label.text)

