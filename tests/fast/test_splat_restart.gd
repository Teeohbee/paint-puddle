extends GameSuite
func settle():
	await get_tree().process_frame
	await get_tree().process_frame
func test_splat_restart() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var studio = load("res://paint/paint_studio.gd")
	studio.colour_set = "printer"
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	check(get_tree().current_scene.colour_set == "paint", "splat uses paint colours")
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	check(get_tree().current_scene.colour_set == "paint", "still paint colours after a restart")
	check(get_tree().current_scene.puddles.has("red") and not get_tree().current_scene.puddles.has("cyan"), "paint puddles after restart")
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
	await settle()
	check(studio.colour_set == "printer", "the Paint menu's choice is back afterwards")
