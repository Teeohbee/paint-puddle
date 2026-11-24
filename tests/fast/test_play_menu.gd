extends GameSuite
# The play menu: the places in a two-row grid, Back on its own to the left. Write has Splat's old place;
# Splat is archived, so it has no tile.

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
	await frames(2)

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func tile(word):
	for each in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if each.word == word: return each
	return null

func open_play_menu():
	MenuScreen.last_choices.erase("play_menu")
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)

func centre(word):
	return tile(word).get_global_rect().get_center()

func test_the_places_sit_in_a_grid_with_back_on_its_own_to_the_left() -> void:
	await open_play_menu()
	var top_row = ["Meadow", "Hills", "Paint", "Write"]
	var bottom_row = ["Map", "Clock", "Book", "1 Player"]
	var top_y = centre("Meadow").y
	var bottom_y = centre("Map").y
	check(bottom_y > top_y + 150, "the second row is below the first: %s vs %s" % [top_y, bottom_y])
	for column in 4:
		check(absf(centre(top_row[column]).y - top_y) < 1.0, "%s is in the top row" % top_row[column])
		check(absf(centre(bottom_row[column]).y - bottom_y) < 1.0, "%s is in the bottom row" % bottom_row[column])
		check(absf(centre(top_row[column]).x - centre(bottom_row[column]).x) < 1.0, "%s sits over %s" % [top_row[column], bottom_row[column]])
	check(tile("Back").get_global_rect().end.x < tile("Meadow").get_global_rect().position.x, "Back is left of the grid")
	check(absf(centre("Back").y - (top_y + bottom_y) / 2.0) < 1.0, "and halfway between the rows: %s" % centre("Back").y)
	var screen = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for word in ["Back"] + top_row + bottom_row:
		check(screen.encloses(tile(word).get_global_rect()), "%s is on the screen" % word)

func test_the_d_pad_moves_around_the_grid_and_out_to_back() -> void:
	await open_play_menu()
	check(focused_word() == "Meadow", "starts on Meadow: " + focused_word())
	for word in ["Hills", "Paint", "Write", "Write"]:
		await press("ui_right")
		check(focused_word() == word, "right along the top row reaches %s: %s" % [word, focused_word()])
	await press("ui_down")
	check(focused_word() == "1 Player", "down from Write is the tile below it: " + focused_word())
	await press("ui_down")
	check(focused_word() == "1 Player", "down on the bottom row stays put: " + focused_word())
	for word in ["Book", "Clock", "Map", "Back", "Back"]:
		await press("ui_left")
		check(focused_word() == word, "left along the bottom row reaches %s: %s" % [word, focused_word()])
	await press("ui_right")
	check(focused_word() == "Meadow", "right from Back goes into the grid at Meadow: " + focused_word())
	await press("ui_up")
	check(focused_word() == "Meadow", "up on the top row stays put: " + focused_word())
	await press("ui_down")
	check(focused_word() == "Map", "down from Meadow is Map: " + focused_word())
	await press("ui_up")
	check(focused_word() == "Meadow", "and up again is Meadow: " + focused_word())

func test_splat_is_archived_and_write_has_its_place() -> void:
	await open_play_menu()
	check(tile("Splat") == null, "no Splat tile")
	check(tile("Write") != null, "a Write tile")

func test_coming_back_from_splat_lands_on_meadow() -> void:
	MenuScreen.remember_choice("play_menu", "splat")
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)
	check(focused_word() == "Meadow", "a remembered Splat falls back to Meadow: " + focused_word())

func test_write_opens_the_letter_picker() -> void:
	await open_play_menu()
	tile("Write").chosen.emit()
	await frames(2)
	check(SceneManager.is_changing_scene, "picking Write goes somewhere")
	check(MenuScreen.last_choice("play_menu", "") == "write", "and it's remembered")

# Any tile can be taped off while its place is rebuilt: locked, no padlock, and pressing it never opens it
func test_a_tile_under_construction_is_locked_without_a_padlock() -> void:
	var tile := MenuTile.new()
	add_child(tile)
	var opened := [false]
	tile.chosen.connect(func(): opened[0] = true)
	tile.is_under_construction = true
	check(tile.is_locked and not tile.shows_padlock, "locked, no padlock")
	tile.pressed.emit()
	check(not opened[0], "pressing it doesn't open it")
	tile.queue_free()
