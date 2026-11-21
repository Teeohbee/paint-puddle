extends GameSuite
# Splat party is archived: off the play menu, but it still boots, and moving doesn't paint trails, so it's
# ready to be reworked.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func test_splat_place() -> void:
	var studio_script = load("res://paint/paint_studio.gd")
	var party_script = load("res://paint/splat_party.gd")
	var settings = GameSettings
	settings.load_from_disk()
	studio_script.colour_set = "printer"
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await settle()
	var menu = get_tree().current_scene
	var tile_words = []
	for tile in menu.find_children("*", "MenuTile", true, false):
		tile_words.append(tile.word)
	check(not tile_words.has("Splat"), "Splat is archived: no tile on the play menu: %s" % [tile_words])
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	var party = get_tree().current_scene
	check(party.get_script() == party_script, "Splat party boots")
	check(studio_script.colour_set == "paint", "it uses paint colours even after the Paint menu chose printer")
	check(party.canvas.colour_set == "paint", "and so does its paper")
	check(party.controls_hint.shows_act_button and not party.controls_hint.shows_jump, "the hint shows four arrows and A")
	var player = party.players[0]
	player.paint_bits = PaintMixing.bits_of("red", "paint")
	player.blob.change_paint("red")
	for step in 20:
		player.blob.position += Vector2(10, 0)
		await get_tree().physics_frame
	var painted = 0
	for cell in party.canvas.cells:
		if cell != 0: painted += 1
	check(painted == 0, "driving a painted blob about leaves the paper clean: %d cells" % painted)
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await settle()
	check(studio_script.colour_set == "printer", "leaving Splat puts the Paint menu's choice back")
