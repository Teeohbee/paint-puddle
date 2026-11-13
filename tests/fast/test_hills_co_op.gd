extends GameSuite
# Two-player Hills: the camera follows both blobs, and a blob left far behind is carried to its friend.

func open_level(level_number):
	load("res://hills/hills_level.gd").level_to_play = level_number
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	for frame in 4: await get_tree().process_frame
	return get_tree().current_scene

# Adds a second blob straight into the level, the way joining will
func add_second_blob(level, x):
	var second_blob = load("res://blob/hills_blob.gd").new()
	second_blob.position = Vector2(x, level.ground.height_at(x) - 46.0 - 2)
	level.add_child(second_blob)
	level.players.append(load("res://hills/hills_player.gd").new(second_blob, level.level.paint))
	return second_blob

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func pad_button(device, button, pressed):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	return event

func find_pot(level):
	for child in level.effects_layer.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("hills/paint_pot.gd"):
			return child
	return null

func test_hills_co_op() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var level = await open_level(0)
	for frame in 60: await get_tree().physics_frame
	check(level.camera.global_position.distance_to(level.blob.position) < 2.0, "solo: the camera follows the blob: %s vs %s" % [level.camera.global_position, level.blob.position])
	var second_blob = add_second_blob(level, level.nearest_ground_x(1000.0))
	level.blob.position = Vector2(level.blob.position.x, level.blob.position.y)
	for frame in 60: await get_tree().physics_frame
	var midpoint = (level.blob.position + second_blob.position) / 2.0
	check(level.camera.global_position.distance_to(midpoint) < 2.0, "two: the camera follows the midpoint: %s vs %s" % [level.camera.global_position, midpoint])
	check(not level.blob.is_being_carried and not second_blob.is_being_carried, "close together: nobody is carried")

	# Far apart: the one behind is carried up to the one in front
	var far_x = level.nearest_ground_x(level.blob.position.x + level.MAX_SEPARATION + 700.0)
	second_blob.position = Vector2(far_x, level.ground.height_at(far_x) - 46.0 - 2)
	second_blob.velocity = Vector2.ZERO
	var was_carried = false
	for frame in 20:
		await get_tree().physics_frame
		was_carried = was_carried or level.blob.is_being_carried
	check(was_carried and not second_blob.is_being_carried, "the blob left behind is carried, the leader isn't")
	for frame in 240: await get_tree().physics_frame
	check(not level.blob.is_being_carried, "the carrying finishes")
	check(absf(level.blob.position.x - second_blob.position.x) < level.MAX_SEPARATION, "and they end up close: %.0f apart" % absf(level.blob.position.x - second_blob.position.x))
	await join_checks()

func join_checks():
	PlayerSession.choose_one_player()
	var solo_level = await open_level(1)
	for frame in 30: await get_tree().physics_frame
	check(solo_level.players.size() == 1 and not solo_level.blob.look.wears_bow, "solo to start, no bow")
	PlayerSession.choose_two_players(0, 1)
	var level = await open_level(1)
	for frame in 30: await get_tree().physics_frame
	check(level.players.size() == 2, "a chosen second pad means two players from the start")
	var one = level.players[0]
	var two = level.players[1]
	check(two.blob.look.wears_bow and not one.blob.look.wears_bow, "player two wears the bow")
	for frame in 40: await get_tree().physics_frame
	# Each pad drives only its own blob
	var one_x = one.blob.position.x
	var two_x = two.blob.position.x
	Input.parse_input_event(pad_button(1, JOY_BUTTON_DPAD_RIGHT, true))
	for frame in 30: await get_tree().physics_frame
	Input.parse_input_event(pad_button(1, JOY_BUTTON_DPAD_RIGHT, false))
	check(two.blob.position.x > two_x + 20 and absf(one.blob.position.x - one_x) < 1.0, "pad 1 walks only player two")
	# Each pad jumps only its own blob
	for frame in 30: await get_tree().physics_frame
	var one_jumps = one.blob.mover.jumps_made
	var two_jumps = two.blob.mover.jumps_made
	Input.parse_input_event(pad_button(1, JOY_BUTTON_A, true))
	for frame in 5: await get_tree().physics_frame
	Input.parse_input_event(pad_button(1, JOY_BUTTON_A, false))
	check(two.blob.mover.jumps_made == two_jumps + 1 and one.blob.mover.jumps_made == one_jumps, "pad 1's button jumps only player two")
	for frame in 40: await get_tree().physics_frame
	Input.parse_input_event(pad_button(0, JOY_BUTTON_A, true))
	for frame in 5: await get_tree().physics_frame
	Input.parse_input_event(pad_button(0, JOY_BUTTON_A, false))
	check(one.blob.mover.jumps_made == one_jumps + 1 and two.blob.mover.jumps_made == two_jumps + 1, "pad 0's button jumps only player one")
	# Own paint from the pot
	for frame in 60: await get_tree().physics_frame
	var pot = find_pot(level)
	var paint_before = one.paint
	var pot_paint_name = pot.paint_name
	two.blob.position = pot.position
	for frame in 10: await get_tree().physics_frame
	var expected = load("res://core/paint_mixing.gd").mix(paint_before, pot_paint_name)
	check(two.paint == expected and one.paint == paint_before, "the pot mixes only the blob that touched it: %s / %s" % [two.paint, one.paint])
	# Either blob at the flag finishes the level
	var flag_x = level.ground.level_length - 160
	level.players[1].blob.position = Vector2(flag_x, level.ground.height_at(flag_x) - 60)
	for frame in 10: await get_tree().physics_frame
	check(level.is_finished and not level.players[0].blob.can_move and not level.players[1].blob.can_move, "either blob at the flag finishes the level for both")
