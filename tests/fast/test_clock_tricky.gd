extends GameSuite
# Tricky clock faces: one unlocks per rung cleared, and a tricky replay of a cleared rung deals a
# random unlocked face on every card.

func open_menu() -> Control:
	get_tree().change_scene_to_file("res://ui/clock_menu.tscn")
	await frames(4)
	return get_tree().current_scene

func open_tricky_rung(rung: int) -> ClockMode:
	ClockMode.tricky_replay = true
	ClockMode.rung_to_play = rung
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	return get_tree().current_scene

func locked_rungs(menu) -> Array[int]:
	var locked: Array[int] = []
	for index in menu.rung_tiles.size():
		if menu.rung_tiles[index].is_locked:
			locked.append(index + 1)
	return locked

func test_there_is_no_tricky_tile_before_a_rung_is_cleared() -> void:
	var menu = await open_menu()
	check(not menu.tricky.visible, "no Tricky tile yet")

func test_the_tricky_tile_switches_to_cleared_rungs_only() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 2)
	var menu = await open_menu()
	check(menu.tricky.visible and menu.tricky.subtitle == "off", "a Tricky tile, off")
	check(locked_rungs(menu) == [4, 5, 6, 7, 8], "plain: up to the climbing rung: %s" % [locked_rungs(menu)])
	menu.tricky.chosen.emit()
	await frames(2)
	check(ClockMode.tricky_replay and menu.tricky.subtitle == "on" and menu.heading.text == "Tricky clocks", "tricky is on")
	check(locked_rungs(menu) == [3, 4, 5, 6, 7, 8], "tricky: only the cleared rungs: %s" % [locked_rungs(menu)])

func test_a_tricky_replay_deals_unlocked_faces_and_saves_nothing() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 3)
	var mode: ClockMode = await open_tricky_rung(2)
	check(not mode.is_climbing, "a tricky replay isn't climbing")
	check(GameSettings.get_clock_task_deck().is_empty(), "nothing saved")
	var unlocked: Array[String] = ClockRungs.tricky_faces_unlocked(3)
	var faces_seen: Dictionary = {}
	for card in mode.task_runner.deck:
		mode.on_card_started(card)
		faces_seen[mode.clock_face.face_name] = true
	for face in faces_seen:
		check(unlocked.has(face), "only unlocked faces: %s" % face)

# Tricky faces are parked while the ladder is rebuilt: clearing a rung keeps the home face
func test_clearing_a_rung_keeps_the_home_face() -> void:
	GameSettings.record_progress("clock_run_day", 20000101)
	GameSettings.record_progress("clock_first_try_run", 4)
	ClockMode.rung_to_play = 1
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	var one_card: Array[ClockCard] = [ClockCard.new(false, 7 * 60)]
	mode.task_runner.start_deck(1, one_card)
	await frames(2)
	Input.action_press("act")
	await frames(2)
	Input.action_release("act")
	await frames(roundi(60 * (ClockTaskRunner.SECONDS_TO_CELEBRATE + 0.5)))
	check(GameSettings.get_progress("clock_rungs_cleared") == 1, "the rung is cleared")
	check(mode.clock_face.face_name == "", "no tricky face shows: '%s'" % mode.clock_face.face_name)

func test_every_tricky_face_draws_without_errors() -> void:
	var mode: ClockMode = await open_tricky_rung(3)
	for face in ClockRungs.TRICKY_FACES:
		mode.clock_face.show_face(face)
		await frames(2)
	check(true, "drew all eight")
