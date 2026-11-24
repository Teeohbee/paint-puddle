extends GameSuite
# The Clock menu: Back, then a big Play with the clock tile (where the cursor starts), then the
# ladder - the built rungs, and faded "Coming soon" tiles for the rest. No Tricky tile while the
# tricky faces are parked.

func open_menu() -> Control:
	get_tree().change_scene_to_file("res://ui/clock_menu.tscn")
	await frames(4)
	return get_tree().current_scene

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func rect_of(tile) -> Rect2:
	return tile.get_global_rect()

func test_back_then_free_play_then_the_ladder_all_on_screen() -> void:
	var menu = await open_menu()
	check(rect_of(menu.back).end.x < rect_of(menu.free_play).position.x, "Back is left of Play with the clock")
	check(rect_of(menu.free_play).end.x < rect_of(menu.rung_tiles[0]).position.x, "and that's left of the rungs")
	check(rect_of(menu.free_play).size.y > rect_of(menu.rung_tiles[0]).size.y, "Play with the clock is the big tile")
	var screen = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for tile in [menu.back, menu.free_play] + menu.rung_tiles + menu.coming_soon_tiles:
		check(screen.encloses(rect_of(tile)), "%s is on the screen" % tile.word)

func test_the_cursor_starts_on_free_play() -> void:
	var menu = await open_menu()
	check(focused_word() == menu.free_play.word, "on Play with the clock: %s" % focused_word())

func test_free_play_opens_free_play() -> void:
	var menu = await open_menu()
	menu.free_play.chosen.emit()
	await frames(40)
	var mode = get_tree().current_scene
	check(mode is ClockMode and ClockMode.free_play and mode.task_runner == null, "free play opens")

func test_three_rungs_then_coming_soon() -> void:
	var menu = await open_menu()
	check(menu.rung_tiles.size() == 3, "rungs 1-3: %d" % menu.rung_tiles.size())
	check(menu.coming_soon_tiles.size() == 3, "three coming soon")
	for tile in menu.coming_soon_tiles:
		check(tile.is_locked and not tile.shows_padlock and tile.subtitle == "Coming soon", "%s is coming soon" % tile.word)
	for rung in range(ClockRungs.RUNGS_BUILT + 1, 4):
		var tile = menu.rung_tiles[rung - 1]
		check(tile.is_locked and tile.subtitle == "Coming soon", "rung %d isn't built yet" % rung)

func test_open_everything_stops_at_the_built_rungs() -> void:
	GameSettings.set_setting("open_all_clock_rungs", 1)
	var menu = await open_menu()
	for rung in 3:
		check(menu.rung_tiles[rung].is_locked == (rung + 1 > ClockRungs.RUNGS_BUILT), "rung %d open only if built" % (rung + 1))

func test_there_is_no_tricky_tile_and_tricky_replays_are_off() -> void:
	ClockMode.tricky_replay = true
	var menu = await open_menu()
	check(not "tricky" in menu, "no Tricky tile")
	check(not ClockMode.tricky_replay, "tricky replays are off")

func test_picking_a_rung_turns_free_play_off() -> void:
	ClockMode.free_play = true
	var menu = await open_menu()
	menu.rung_tiles[0].chosen.emit()
	await frames(40)
	var mode = get_tree().current_scene
	check(mode is ClockMode and not ClockMode.free_play and mode.task_runner != null, "rung 1 plays its cards")

func test_every_ladder_word_is_the_same_size() -> void:
	var menu = await open_menu()
	var tiles: Array = [menu.free_play] + menu.rung_tiles + menu.coming_soon_tiles
	var sizes: Dictionary = {}
	for tile: MenuTile in tiles:
		sizes[tile.word_font_size] = true
		check(tile.word_size_to_fit(tile.custom_minimum_size) >= tile.word_font_size, "%s fits at the shared size" % tile.word)
	check(sizes.size() == 1 and not sizes.has(0), "one shared word size: %s" % [sizes.keys()])
