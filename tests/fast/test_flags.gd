extends GameSuite
# Flags and the Countries part of the Book.

class Probe extends Control:
	var drawn_id = ""
	func _draw():
		FlagDrawings.draw(self, drawn_id, Vector2(150, 100), 240)

func test_flags() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var Book = load("res://ui/book.gd")
	var countries = Book.countries_in_the_book()
	check(countries.size() >= 120, "the Book lists %d countries" % countries.size())
	var missing = countries.filter(func(id): return not FlagDrawings.can_draw(id))
	check(missing.is_empty(), "every country has a flag: missing %s" % [missing])
	var colours = FlagDrawings.COLOURS
	var bad = []
	for id in FlagDrawings.FLAGS:
		var spec = FlagDrawings.FLAGS[id]
		var names = []
		if spec.has("bg"): names.append(spec["bg"])
		for stripe in spec.get("h", []) + spec.get("v", []): names.append(String(stripe).split(":")[0])
		for op in spec.get("ops", []):
			if op[0] != "jack": names.append(op[1])
		if not names.all(func(n): return colours.has(n)): bad.append(id)
	check(bad.is_empty(), "every colour name exists: %s" % [bad])
	check(countries == Book.entries_for("countries"), "entries_for gives the countries")
	check(Book.found_count("countries") == 0, "none found to start")
	settings.record_found("countries_found", "france")
	check(Book.found_count("countries") == 1 and not Book.is_finished("countries"), "one found")
	# drawing every flag doesn't error
	var probe = Probe.new()
	get_tree().root.add_child(probe)
	for id in FlagDrawings.FLAGS:
		probe.drawn_id = id
		probe.queue_redraw()
		await get_tree().process_frame
	# every flag drew: a drawing error fails the test as a runtime error
	# the Book page
	var book = load("res://ui/book.tscn").instantiate()
	get_tree().root.add_child(book)
	await frames(3)
	book.open_section("countries")
	await frames(2)
	check(book.entries.size() == countries.size() and book.entry_tiles.size() == book.ENTRIES_PER_PAGE, "the Countries page is full: %d" % book.entry_tiles.size())
	var france_page = countries.find("france") / book.ENTRIES_PER_PAGE
	book.show_page(france_page)
	await frames(2)
	var found_tiles = book.entry_tiles.filter(func(t): return t.picture == "flag:france")
	check(found_tiles.size() == 1, "France shows its flag")
	# long names get a short tile label, and the close-up keeps the whole name
	var bosnia_page = countries.find("bosnia_and_herzegovina") / book.ENTRIES_PER_PAGE
	settings.record_found("countries_found", "bosnia_and_herzegovina")
	book.show_page(bosnia_page)
	await frames(2)
	var bosnia_tile = book.entry_tiles.filter(func(t): return t.picture == "flag:bosnia_and_herzegovina")[0]
	bosnia_tile.grab_focus()
	await get_tree().process_frame
	check(bosnia_tile.word == "" and book.name_plate.text == "Bosnia and Herzegovina", "the whole name goes on the name plate, not the tile: %s" % book.name_plate.text)
	book.show_close_up(bosnia_tile)
	await frames(2)
	check(book.close_up.get_child(1).get_child(0).word == "Bosnia and Herzegovina", "the close-up has the whole name")
	# resetting the Map clears the countries and lets the Book cheer again
	for id in countries: settings.record_found("countries_found", id)
	settings.record_found("book_parts_celebrated", "countries")
	check(Book.is_finished("countries"), "all found finishes the part")
	settings.reset_part("map")
	check(Book.found_count("countries") == 0 and not settings.has_found("book_parts_celebrated", "countries"), "the Map reset empties the part and its cheer")
