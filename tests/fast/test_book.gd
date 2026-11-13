extends GameSuite
# The book shows every word a Meadow task can bring to life: found ones with
# their picture, the rest as a grey "?". Picking a picture shows it big.

func press(action):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().create_timer(0.25).timeout

func focused():
	return get_tree().root.gui_get_focus_owner()

func open_book():
	get_tree().change_scene_to_file("res://ui/book.tscn")
	await get_tree().create_timer(0.6).timeout
	check(get_tree().current_scene.section == "" and focused().word == "Words", "the book opens on Words or Colours, on Words")
	await press("ui_accept")
	return get_tree().current_scene

func entry_tiles(book):
	return book.entry_tiles

## The name of whatever tile you're on, on a plate under the grid.
func check_name_plate(book, tiles):
	var plate = book.name_plate
	check(plate.get_global_rect().position.y > book.page_footer.get_global_rect().end.y - 1 and plate.get_global_rect().end.y < 1060, "the name plate sits under the dots, on screen: %s" % plate.get_global_rect())
	tiles[1].grab_focus()
	await get_tree().process_frame
	check(plate.modulate.a == 1.0 and plate.text == "DOG" and plate.picture == "thing:dog", "on the dog it says DOG, with the dog: %s %s" % [plate.text, plate.picture])
	tiles[0].grab_focus()
	await get_tree().process_frame
	check(plate.text == "Not found yet" and plate.picture == "", "on a mystery it says not found yet: " + plate.text)
	book.back_tile.grab_focus()
	await get_tree().process_frame
	check(plate.modulate.a == 0.0, "on Back it's hidden")
	var place = plate.get_global_rect()
	tiles[1].grab_focus()
	await get_tree().process_frame
	check(plate.get_global_rect() == place, "and it never moves")
	tiles[0].grab_focus()

func test_book() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	var book = await open_book()
	var words = book.entries
	check(words.size() >= 20 and words[0] == "cat" and words[1] == "dog", "the book lists the task words in order: %s" % [words.slice(0, 4)])
	check(book.found_label.text == "Spell a word in the Meadow to fill this page.", "an empty book says how to fill it")
	var tiles = entry_tiles(book)
	check(tiles.size() == 32, "thirty-two to a page")
	check(tiles.all(func(tile): return tile.picture == "" and tile.is_locked and not tile.shows_padlock), "nothing found: all question marks, no padlocks")
	check(focused() == tiles[0], "the D-pad starts on the first entry")
	var pages_per_part = {}
	for part in ["colours", "countries", "words"]:
		book.open_section(part)
		pages_per_part[part] = book.page_count()
		await get_tree().process_frame
	check(pages_per_part == {"words": 2, "colours": 1, "countries": 5}, "pages: Words 2, Colours 1, Countries 5: %s" % pages_per_part)

	settings.record_found("words_spelled", "dog")
	var page_two_word = words[32]
	settings.record_found("words_spelled", page_two_word)
	settings.record_found("words_spelled", "yak")
	var first_country = load("res://ui/book.gd").countries_in_the_book()[0]
	settings.record_found("countries_found", first_country)
	book = await open_book()
	tiles = entry_tiles(book)
	check(book.found_label.text == "You have found 2 of %d!" % words.size(), "it counts what's found, ignoring words it doesn't know: " + book.found_label.text)
	check(tiles[1].picture == "thing:dog" and tiles[1].word == "", "the dog tile has its picture, and its word goes on the name plate")
	check(tiles[0].picture == "" and tiles[0].word == "", "the cat is still a mystery")

	await press("ui_right")
	check(focused() == tiles[1], "right moves to the dog")
	await press("ui_accept")
	check(book.close_up != null and focused().picture == "thing:dog" and focused().word == "DOG", "picking the dog shows it big, with its word")
	var big_dog = focused()
	for direction in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_focus_next", "ui_focus_prev"]:
		await press(direction)
		check(focused() == big_dog, "%s stays on the big picture, not the tiles behind it" % direction)
	await press("ui_accept")
	check(book.close_up == null and focused() == tiles[1], "picking it again puts it away, back on the dog")

	await press("ui_left")
	await press("ui_accept")
	check(book.close_up == null, "a mystery entry doesn't open")

	# Back sits in the top-left corner, up from the top row
	check(book.back_tile.get_global_rect().end.x < 300 and book.back_tile.get_global_rect().end.y < 260, "Back is in the top-left corner: %s" % book.back_tile.get_global_rect())
	for column in 8:
		tiles[column].grab_focus()
		await press("ui_up")
		check(focused() == book.back_tile, "up from top-row tile %d goes to Back" % (column + 1))
	await press("ui_left")
	check(focused() == book.back_tile, "left on Back does nothing")
	await press("ui_right")
	check(focused() == book.back_tile, "right on Back does nothing")
	await press("ui_down")
	check(focused() == tiles[0], "down from Back lands on the first tile")
	# The page tabs, either side of the grid
	var page_count = ceili(words.size() / 32.0)
	check(book.page_footer.get_child(0).page == 0 and book.page_footer.get_child(0).page_count == page_count, "the dots say which page")
	check(book.previous_page_tile.get_global_rect().end.x < tiles[0].get_global_rect().position.x and book.next_page_tile.get_global_rect().position.x > tiles[7].get_global_rect().end.x, "the tabs sit either side of the grid")
	check(book.previous_page_tile.size.y > 3 * book.previous_page_tile.size.x, "and they're tall: %s" % book.previous_page_tile.size)
	check(book.page_footer.get_global_rect().position.y > tiles[24].get_global_rect().end.y, "the page dots are under the grid")
	await check_name_plate(book, tiles)
	check(book.previous_page_tile.is_locked and book.previous_page_tile.focus_mode == Control.FOCUS_NONE, "page 1 can't go back a page, and the D-pad can't land on it")
	check(not book.next_page_tile.is_locked, "but can go to the next page")
	tiles[8].grab_focus()
	await press("ui_left")
	check(focused() == tiles[8], "left from column 1 does nothing when Back a page is greyed")
	tiles[15].grab_focus()
	await press("ui_right")
	check(focused() == book.next_page_tile, "right from column 8 lands on Next page")
	check(book.page == 0, "landing on a tab doesn't turn the page")
	for direction in ["ui_up", "ui_down", "ui_right"]:
		await press(direction)
		check(focused() == book.next_page_tile, "%s on Next page does nothing" % direction)
	tiles[24].grab_focus()
	await press("ui_down")
	check(focused() == tiles[24], "down from the bottom row does nothing")
	book.next_page_tile.grab_focus()
	await press("ui_accept")
	tiles = entry_tiles(book)
	check(book.page == 1 and focused() == tiles[0], "A on Next page turns to the last page, where Next is greyed, so the D-pad goes to the first entry")
	check(book.page_footer.get_child(0).page == 1, "the dots say page 2")
	check(tiles[0].picture == "thing:" + page_two_word, "the 33rd word is first on page two: " + page_two_word)
	tiles[tiles.size() - 1].grab_focus()
	await press("ui_right")
	check(focused() == tiles[tiles.size() - 1], "right from the last tile does nothing when Next page is greyed")
	tiles[5].grab_focus()
	await press("ui_down")
	check(focused() == tiles[5], "on a short page, down from a tile with nothing under it does nothing")
	tiles[8].grab_focus()
	await press("ui_left")
	check(focused() == book.previous_page_tile, "left from column 1 lands on Back a page")
	await press("ui_accept")
	check(book.page == 0 and focused() == book.entry_tiles[0], "Back a page to page 1 lands on the first entry, as Back a page is greyed there")
	# Mashing the tabs, in Countries with five pages
	book.open_section("countries")
	await get_tree().create_timer(0.3).timeout
	check(book.entry_tiles[0].word == "" and book.entry_tiles[0].picture == "flag:" + first_country, "a country tile is just its flag, no name")
	book.next_page_tile.grab_focus()
	for turn in 3:
		await press("ui_accept")
		check(book.page == turn + 1 and focused() == book.next_page_tile, "A on Next page turns to page %d and stays on the tab" % (turn + 2))
	await press("ui_accept")
	check(book.page == 4 and book.next_page_tile.is_locked and focused() == book.entry_tiles[0], "mashing reaches the last page, where Next is greyed and the D-pad goes to the first entry")
	book.previous_page_tile.grab_focus()
	for turn in 4:
		await press("ui_accept")
	check(book.page == 0, "and mashing Back a page goes back to page 1")
	# The tabs remember the row you came from
	book.show_page(2)
	await get_tree().create_timer(0.3).timeout
	tiles = entry_tiles(book)
	tiles[8].grab_focus()
	await press("ui_left")
	check(focused() == book.previous_page_tile, "left from row 2 lands on Back a page")
	await press("ui_right")
	check(focused() == tiles[8], "and right goes back to row 2, column 1")
	tiles[15].grab_focus()
	await press("ui_right")
	await press("ui_left")
	check(focused() == tiles[15], "right from row 2's end then left comes back to it")
	tiles[16].grab_focus()
	await press("ui_left")
	await press("ui_accept")
	check(book.page == 1 and focused() == book.previous_page_tile, "turning back from row 3 stays on the tab")
	await press("ui_right")
	check(focused() == book.entry_tiles[16], "and right lands on row 3 of the new page")
	book.entry_tiles[23].grab_focus()
	await press("ui_right")
	await press("ui_accept")
	await press("ui_left")
	check(book.page == 2 and focused() == book.entry_tiles[23], "turning on from row 3 then left lands on the end of row 3")
	book.entry_tiles[31].grab_focus()
	await press("ui_right")
	book.show_page(book.page_count() - 1, book.FOCUS_PREVIOUS_PAGE)
	await get_tree().create_timer(0.3).timeout
	check(focused() == book.previous_page_tile and book.entry_tiles.size() <= 8, "the last page is one short row")
	await press("ui_right")
	check(focused() == book.entry_tiles[0], "so the remembered row 4 becomes its only row")
	book.show_page(0)
	await get_tree().create_timer(0.3).timeout
	# A one-page part hides its tabs and page label but keeps their space
	var words_grid_corner = book.entry_tiles[9].get_global_rect().position
	book.open_section("colours")
	await get_tree().create_timer(0.3).timeout
	check(book.page_count() == 1 and book.previous_page_tile.modulate.a == 0.0 and book.next_page_tile.modulate.a == 0.0, "Colours has one page and no visible tabs")
	check(book.page_footer.modulate.a == 0.0, "nor page dots")
	book.entry_tiles[0].grab_focus()
	await get_tree().process_frame
	check(book.name_plate.modulate.a == 1.0 and book.name_plate.text == "Not found yet", "but the name plate still shows: " + book.name_plate.text)
	check(book.next_page_tile.focus_mode == Control.FOCUS_NONE and book.previous_page_tile.focus_mode == Control.FOCUS_NONE, "and the D-pad can't land on the hidden tabs")
	check(book.entry_tiles[9].get_global_rect().position == words_grid_corner, "its grid lines up with the others: %s vs %s" % [book.entry_tiles[9].get_global_rect().position, words_grid_corner])
	book.open_section("words")
	await get_tree().create_timer(0.3).timeout
	# Back goes straight out
	book.back_tile.grab_focus()
	await press("ui_accept")
	check(book.section == "" and focused().word == "Words", "Back goes straight to the parts, on Words")
	check(focused().subtitle == "2 of 42", "Words says how many are found: " + focused().subtitle)
