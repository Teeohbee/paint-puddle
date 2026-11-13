extends GameSuite
# Two-player Paint: a second pad joins on A, each blob has its own paint and pad, the blobs pass through
# each other, and player two leaves when their pad disconnects.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func pad_a(device):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event

func press_right_on(device, pressed):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_DPAD_RIGHT
	event.pressed = pressed
	Input.parse_input_event(event)

func test_paint_co_op() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	PlayerSession.choose_one_player()
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await settle()
	var solo = get_tree().current_scene
	check(solo.players.size() == 1, "solo to start")
	check(not solo.blob.look.wears_bow, "player one has no bow")
	PlayerSession.choose_two_players(0, 1)
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await settle()
	var studio = get_tree().current_scene
	check(studio.players.size() == 2, "a chosen second pad means two players from the start")
	var one = studio.players[0]
	var two = studio.players[1]
	check(two.blob.look.wears_bow and not one.blob.look.wears_bow, "player two wears the bow")
	check(one.brush_number != two.brush_number, "each has their own brush")

	# Each pad drives its own blob
	one.blob.position = Vector2(500, 300)
	two.blob.position = Vector2(500, 600)
	one.blob.velocity = Vector2.ZERO
	two.blob.velocity = Vector2.ZERO
	await settle()
	press_right_on(1, true)
	for frame in 20: await get_tree().physics_frame
	press_right_on(1, false)
	check(two.blob.position.x > 520 and absf(one.blob.position.x - 500) < 1.0, "pad 1 drives only player two: %.0f vs %.0f" % [two.blob.position.x, one.blob.position.x])
	press_right_on(0, true)
	for frame in 20: await get_tree().physics_frame
	press_right_on(0, false)
	check(one.blob.position.x > 520, "pad 0 drives player one: %.0f" % one.blob.position.x)

	# Each blob mixes its own paint
	one.blob.position = studio.puddles["red"].position
	for frame in 5: await get_tree().physics_frame
	two.blob.position = studio.puddles["blue"].position
	for frame in 5: await get_tree().physics_frame
	check(one.blob.paint_name == "red" and two.blob.paint_name == "blue", "own paint each: %s and %s" % [one.blob.paint_name, two.blob.paint_name])

	# The blobs pass through each other
	one.blob.position = Vector2(900, 300)
	two.blob.position = Vector2(1000, 300)
	await settle()
	press_right_on(0, true)
	for frame in 60: await get_tree().physics_frame
	press_right_on(0, false)
	check(one.blob.position.x > 1000, "blobs pass through each other: %.0f" % one.blob.position.x)

	# A crossing trail mixes once
	studio.canvas.clear_paper()
	one.paint_bits = PaintMixing.bits_of("red", studio.colour_set)
	two.paint_bits = PaintMixing.bits_of("blue", studio.colour_set)
	var red = one.paint_bits
	var blue = two.paint_bits
	studio.canvas.paint_line(Vector2(300, 1000), Vector2(300, 1000), red, one.brush_number)
	studio.canvas.paint_line(Vector2(300, 1000), Vector2(500, 1000), red, one.brush_number)
	studio.canvas.paint_line(Vector2(1800, 40), Vector2(1800, 40), blue, two.brush_number)
	studio.canvas.paint_line(Vector2(400, 950), Vector2(400, 1050), blue, two.brush_number)
	studio.canvas.paint_line(Vector2(400, 1050), Vector2(400, 1060), blue, two.brush_number)
	check(studio.canvas.paint_at(Vector2(400, 1000)) == "purple", "the crossing mixes purple: %s" % studio.canvas.paint_at(Vector2(400, 1000)))

	# A pad dropping out keeps both blobs and the picture; the pause menu asks for it back
	var session = PlayerSession
	session.on_joy_connection_changed(1, false)
	studio.get_node("PauseMenu").on_joy_connection_changed(1, false)
	await settle()
	check(studio.players.size() == 2 and is_instance_valid(two.blob), "both blobs stay when a pad drops")
	check(studio.canvas.paint_at(Vector2(400, 1000)) == "purple", "and the picture stays")
