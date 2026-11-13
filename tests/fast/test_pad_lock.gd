extends GameSuite
# With two players, only one pad runs a menu, and a lost pad is replaced by an A press.

func settle():
	for frame in 3: await get_tree().process_frame

func pad_button(device, button, pressed):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	return event

func tap(device, button):
	Input.parse_input_event(pad_button(device, button, true))
	await settle()
	Input.parse_input_event(pad_button(device, button, false))
	await settle()

func focused_word():
	var focus = get_tree().root.gui_get_focus_owner()
	return focus.word if focus else "none"

func test_pad_lock() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var session = PlayerSession

	# Menus: solo, any pad works
	session.choose_one_player()
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await settle()
	await tap(1, JOY_BUTTON_DPAD_RIGHT)
	check(focused_word() == "Hills", "solo: any pad moves the menu: %s" % focused_word())

	# Two players: only player one's pad
	session.choose_two_players(0, 1)
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await settle()
	await tap(1, JOY_BUTTON_DPAD_RIGHT)
	check(focused_word() == "Meadow", "two players: pad 2 cannot move the menu: %s" % focused_word())
	await tap(0, JOY_BUTTON_DPAD_RIGHT)
	check(focused_word() == "Hills", "pad 1 can: %s" % focused_word())

	# Pause: either pad opens it, then only that pad uses it
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await settle()
	var studio = get_tree().current_scene
	var pause = studio.get_node("PauseMenu")
	await tap(1, JOY_BUTTON_START)
	check(pause.is_open and pause.opener_device == 1, "pad 2 can pause, and is the owner")
	await tap(0, JOY_BUTTON_START)
	check(pause.is_open, "pad 1 cannot unpause it")
	await tap(0, JOY_BUTTON_A)
	check(pause.is_open, "nor press Play on")
	await tap(1, JOY_BUTTON_A)
	check(not pause.is_open, "but pad 2 can")
	await tap(0, JOY_BUTTON_START)
	check(pause.is_open and pause.opener_device == 0, "pad 1 pauses next time")
	await tap(0, JOY_BUTTON_START)
	check(not pause.is_open, "and unpauses")

	# Losing player two's pad: pause, ask for A, rebind under a new id
	session.on_joy_connection_changed(1, false)
	pause.on_joy_connection_changed(1, false)
	await settle()
	check(pause.is_open and pause.unplugged_notice.visible and session.missing_slots == [1], "losing pad 2 pauses and waits")
	await tap(0, JOY_BUTTON_A)
	check(pause.unplugged_notice.visible, "player one's A does not fill player two's slot")
	await tap(5, JOY_BUTTON_A)
	check(not pause.unplugged_notice.visible and pause.is_open, "a new pad's A fills it, and the pause menu is back")
	check(session.device_of(1) == 5, "player two is on pad 5: %s" % [session.player_devices])
	await tap(5, JOY_BUTTON_A)
	check(not pause.is_open, "pad 5 now owns the menu")
	var two = studio.players[1]
	Input.parse_input_event(pad_button(5, JOY_BUTTON_DPAD_RIGHT, true))
	await settle()
	check(Input.is_action_pressed("player_two_move_right"), "pad 5 drives player two")
	check(not Input.is_action_pressed("player_one_move_right"), "and not player one")
	Input.parse_input_event(pad_button(5, JOY_BUTTON_DPAD_RIGHT, false))
	await settle()

	# Losing player one's pad too
	session.on_joy_connection_changed(0, false)
	pause.on_joy_connection_changed(0, false)
	await settle()
	check(pause.is_open and session.missing_slots == [0], "losing player one's pad pauses too")
	await tap(5, JOY_BUTTON_A)
	check(pause.unplugged_notice.visible, "player two's pad cannot take player one's slot")
	await tap(0, JOY_BUTTON_A)
	check(not pause.unplugged_notice.visible and session.device_of(0) == 0, "the same id coming back fills it")

	# One controller, two players: B ends two players instead of waiting for a pad that isn't coming
	session.choose_two_players(0, 1)
	session.on_joy_connection_changed(1, false)
	pause.on_joy_connection_changed(1, false)
	await settle()
	check(pause.unplugged_notice.visible and session.missing_slots == [1], "pad 2 lost, waiting")
	await tap(0, JOY_BUTTON_B)
	check(not session.is_two_player() and not session.has_missing_pad(), "B gives up on two players: nobody is missing any more")
	await settle()

	# A menu whose owner pad is gone doesn't lock everyone out
	session.choose_two_players(8, 1)
	session.on_joy_connection_changed(8, false)
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await settle()
	await tap(1, JOY_BUTTON_DPAD_RIGHT)
	check(focused_word() == "Hills", "owner pad gone: any pad works: %s" % focused_word())
	session.choose_one_player()
