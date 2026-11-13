extends GameSuite

func _init():
	await get_tree().process_frame
	await get_tree().process_frame
	var settings = GameSettings
	settings.reset_progress()
	var levels = load("res://hills/hills_levels.gd")
	var level_scene = load("res://hills/hills_level.gd")
	var plain = {"word": "SUN"}
	var longer = {"word": "SUN", "word_medium": "SUNSHINE"}
	check(levels.word_for(plain, "easy") == "SUN", "easy uses word")
	check(levels.word_for(longer, "easy") == "SUN", "easy ignores word_medium")
	check(levels.word_for(plain, "medium") == "SUN", "medium falls back to word")
	check(levels.word_for(longer, "medium") == "SUNSHINE", "medium uses word_medium")
	check(levels.progress_key("easy") != levels.progress_key("medium"), "separate progress keys")
	check(not levels.is_medium_unlocked(), "medium locked on fresh save")
	settings.record_progress("hills_levels_completed", levels.level_count() - 1)
	check(not levels.is_medium_unlocked(), "medium locked at 39 easy")
	settings.set_setting("open_hills_medium", 1)
	check(levels.is_medium_unlocked(), "grown-up switch opens medium")
	settings.set_setting("open_hills_medium", 0)
	settings.record_progress("hills_levels_completed", levels.level_count())
	check(levels.is_medium_unlocked(), "medium unlocked at 40 easy")
	check(levels.is_unlocked(0, "medium") and not levels.is_unlocked(1, "medium"), "medium starts at level 1")
	level_scene.difficulty = "medium"
	level_scene.level_to_play = 0
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var level = get_tree().current_scene
	level.finish.call_deferred()
	await get_tree().process_frame
	check(settings.get_progress("hills_levels_completed_medium") == 1, "finishing on medium counts medium")
	check(settings.get_progress("hills_levels_completed") == levels.level_count(), "easy count untouched")
	settings.reset_part("hills")
	check(settings.get_progress("hills_levels_completed_medium") == 0 and settings.get_progress("hills_levels_completed") == 0, "hills reset clears both")
	get_tree().change_scene_to_file("res://ui/hills_difficulty_menu.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().current_scene != null, "difficulty screen loads")
	get_tree().change_scene_to_file("res://ui/hills_menu.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().current_scene != null, "medium level menu loads")
