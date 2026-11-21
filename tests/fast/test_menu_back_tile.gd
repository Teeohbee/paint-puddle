extends GameSuite
# Every menu's Back tile is the same: purple, the arrow, one size.

func back_tile():
	for tile in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if tile.word == "Back": return tile
	return null

func test_every_menu_has_the_same_back_tile() -> void:
	var sizes = {}
	for scene in ["play_menu", "paint_menu", "hills_difficulty_menu", "meadow_difficulty_menu", "hills_menu", "clock_menu", "book"]:
		get_tree().change_scene_to_file("res://ui/%s.tscn" % scene)
		await frames(4)
		var back = back_tile()
		check(back != null, "%s has a Back tile" % scene)
		if back == null: continue
		sizes[scene] = back.size
		check(back.paint_colour == PaintColours.PURPLE and back.icon_kind == "back", "%s's Back is purple with the arrow" % scene)
	for scene in sizes:
		check(sizes[scene] == MenuScreen.BACK_TILE_SIZE, "%s's Back is the usual size: %s" % [scene, sizes[scene]])
