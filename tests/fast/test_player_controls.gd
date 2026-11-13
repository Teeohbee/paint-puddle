extends GameSuite
# Blobs can listen to one pad only, and SceneManager notes which pad was last used.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func press_right_on(device, pressed):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_DPAD_RIGHT
	event.pressed = pressed
	Input.parse_input_event(event)

func test_player_controls() -> void:
	var controls = load("res://core/player_controls.gd")
	var pad_one = controls.make_pad_actions("player_one", 0, true)
	var pad_two = controls.make_pad_actions("player_two", 1, false)
	check(pad_two == [&"player_two_move_left", &"player_two_move_right", &"player_two_move_up", &"player_two_move_down"], "action names: %s" % [pad_two])
	check(InputMap.has_action("player_two_move_right"), "the runtime actions exist")
	# Rebuilding doesn't pile up duplicate events
	controls.make_pad_actions("player_two", 1, false)
	var joypad_events = InputMap.action_get_events("player_two_move_right").filter(func(event): return event is InputEventJoypadButton)
	check(joypad_events.size() == 1 and joypad_events[0].device == 1, "rebuilding keeps one right button on device 1: %d" % joypad_events.size())
	var keyboard_two = InputMap.action_get_events("player_two_move_right").filter(func(event): return event is InputEventKey)
	var keyboard_one = InputMap.action_get_events("player_one_move_right").filter(func(event): return event is InputEventKey)
	check(keyboard_two.is_empty() and not keyboard_one.is_empty(), "keyboard goes to player one only")
	press_right_on(1, true)
	await settle()
	check(Input.is_action_pressed("player_two_move_right"), "device 1 moves player two")
	check(not Input.is_action_pressed("player_one_move_right"), "and not player one (device 0)")
	press_right_on(1, false)
	await settle()
	press_right_on(0, true)
	await settle()
	check(Input.is_action_pressed("player_one_move_right") and not Input.is_action_pressed("player_two_move_right"), "device 0 moves player one only")
	press_right_on(0, false)
	await settle()
	var blob = auto_free(load("res://blob/meadow_blob.tscn").instantiate())
	check(blob.move_actions == [&"move_left", &"move_right", &"move_up", &"move_down"], "blobs listen to the usual actions by default")
	# Jumping: the act action, per pad
	var act_one = controls.make_pad_act_action("player_one", 0, true)
	var act_two = controls.make_pad_act_action("player_two", 1, false)
	check(act_one == &"player_one_act" and act_two == &"player_two_act", "act action names: %s %s" % [act_one, act_two])
	var act_press = InputEventJoypadButton.new()
	act_press.device = 1
	act_press.button_index = JOY_BUTTON_X
	act_press.pressed = true
	Input.parse_input_event(act_press)
	await settle()
	check(Input.is_action_pressed(act_two) and not Input.is_action_pressed(act_one), "any face button on pad 1 is player two's jump only")
	var act_release = InputEventJoypadButton.new()
	act_release.device = 1
	act_release.button_index = JOY_BUTTON_X
	act_release.pressed = false
	Input.parse_input_event(act_release)
	await settle()
	var keys_one = InputMap.action_get_events(act_one).filter(func(event): return event is InputEventKey)
	var keys_two = InputMap.action_get_events(act_two).filter(func(event): return event is InputEventKey)
	check(not keys_one.is_empty() and keys_two.is_empty(), "space is player one's jump only")
	var hills_blob = auto_free(load("res://blob/hills_blob.gd").new())
	check(hills_blob.act_action == &"act" and hills_blob.move_actions == [&"move_left", &"move_right", &"move_up", &"move_down"], "hills blobs listen to the usual actions by default")
	hills_blob.free()
