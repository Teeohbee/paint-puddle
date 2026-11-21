extends GameSuite
# The Write menu: pick a letter to trace, 26 of them in school's order. Each opens once the one before it is
# traced, or all of them with "Open everything" in the grown-up settings.

func open_write_menu() -> void:
	get_tree().change_scene_to_file("res://ui/write_menu.tscn")
	await frames(4)

func letter_tiles() -> Array:
	return get_tree().current_scene.letter_tiles

func focused_tile():
	return get_tree().root.gui_get_focus_owner()

func test_there_is_a_tile_for_every_letter_in_order() -> void:
	await open_write_menu()
	var tiles: Array = letter_tiles()
	check(tiles.size() == 26, "26 letters: %d" % tiles.size())
	for index in tiles.size():
		check(tiles[index].icon_kind == "text:" + TracingLetters.ORDER[index], "tile %d is %s" % [index, TracingLetters.ORDER[index]])
	var screen := Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for each in tiles:
		check(screen.encloses(each.get_global_rect()), "every letter is on the screen")

func test_a_new_player_starts_on_m_with_the_rest_locked() -> void:
	await open_write_menu()
	var tiles: Array = letter_tiles()
	check(not tiles[0].is_locked, "m is open")
	check(tiles[1].is_locked and tiles[25].is_locked, "the rest are locked")
	check(focused_tile() == tiles[0], "and it starts on m")

func test_tracing_a_letter_opens_the_next() -> void:
	GameSettings.record_progress("letters_traced", 3)
	await open_write_menu()
	var tiles: Array = letter_tiles()
	check(not tiles[3].is_locked, "after 3 letters, d is open")
	check(tiles[4].is_locked, "but t isn't")
	check(focused_tile() == tiles[3], "it starts on d, the next to trace")

func test_open_everything_opens_every_letter() -> void:
	GameSettings.set_setting("open_all_clock_rungs", 1)
	await open_write_menu()
	for each in letter_tiles():
		check(not each.is_locked, "every letter is open")
	check(GameSettings.get_progress("letters_traced") == 0, "without counting them traced")

func test_after_a_letter_it_starts_on_the_one_after() -> void:
	GameSettings.record_progress("letters_traced", 10)
	TracingMode.letter_just_finished = 5
	await open_write_menu()
	check(focused_tile() == letter_tiles()[6], "back from tracing p, it starts on g")

func test_every_letter_traced_starts_on_the_last() -> void:
	GameSettings.record_progress("letters_traced", 26)
	await open_write_menu()
	check(focused_tile() == letter_tiles()[25], "all traced: it starts on q")

func test_picking_a_letter_traces_it() -> void:
	GameSettings.record_progress("letters_traced", 3)
	await open_write_menu()
	letter_tiles()[2].chosen.emit()
	await frames(2)
	check(TracingMode.letter_to_play == 2, "picking s traces s")
	check(SceneManager.is_changing_scene, "and goes to the tracing")

func test_a_locked_letter_does_nothing() -> void:
	await open_write_menu()
	letter_tiles()[5].pressed.emit()
	await frames(2)
	check(not SceneManager.is_changing_scene, "a locked letter stays put")

func test_after_q_tracing_goes_back_to_the_write_menu() -> void:
	check(TracingMode.WRITE_MENU == "res://ui/write_menu.tscn", "after the last letter it's back to the Write menu")

func test_the_grown_up_switch_is_called_open_everything() -> void:
	get_tree().change_scene_to_file("res://ui/options_screen.tscn")
	await frames(4)
	var words: Array = get_tree().current_scene.grown_up_rows.map(func(row): return row.word)
	check(words.has("Open everything"), "the switch says it opens everything: %s" % [words])
	check(not words.has("Open all rungs"), "not just rungs")
