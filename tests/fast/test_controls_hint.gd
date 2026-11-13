extends GameSuite
# The controls reminder in the hills sky: there, out of the way, and lights up when pressed.

func test_controls_hint() -> void:
	var levels = load("res://hills/hills_levels.gd").LEVELS
	var longest_word_level = 0
	for level_index in levels.size():
		if levels[level_index].word.length() > levels[longest_word_level].word.length():
			longest_word_level = level_index
	load("res://hills/hills_level.gd").level_to_play = longest_word_level
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var level = get_tree().current_scene
	var hint = level.controls_hint
	check(hint != null and hint.is_inside_tree(), "the hills show a controls reminder")
	check(hint.get_parent() is CanvasLayer, "it stays put in the sky while the camera moves")
	var hint_rect = Rect2(hint.position, hint.size)
	var bar_rect = Rect2(level.word_bar.position, level.word_bar.size)
	check(not hint_rect.intersects(bar_rect), "it doesn't cover the word bar on the longest word: %s vs %s" % [hint_rect, bar_rect])
	check(hint_rect.position.x >= 0 and hint_rect.position.y >= 0, "it's on screen")

	check(hint.glow["jump"] == 0.0 and hint.glow["right"] == 0.0, "nothing is lit before pressing")
	Input.action_press("act")
	Input.action_press("move_right")
	for frame in 10: await get_tree().process_frame
	check(hint.glow["jump"] > 0.5, "pressing jump lights the jump button")
	check(hint.glow["right"] > 0.5, "pressing right lights the right arrow")
	check(hint.glow["left"] == 0.0, "and not the left one")
	Input.action_release("act")
	Input.action_release("move_right")
	await get_tree().create_timer(0.6).timeout
	check(hint.glow["jump"] < 0.1, "it fades back after letting go")

	# The meadow and paint mode: a D-pad only, as there's nothing to jump
	for scene_path in ["res://meadow/meadow.tscn", "res://paint/paint_studio.tscn"]:
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
		await get_tree().process_frame
		var scene_name = get_tree().current_scene.name
		hint = get_tree().current_scene.controls_hint
		check(hint != null and hint.is_inside_tree() and hint.get_parent() is CanvasLayer, "%s shows a controls reminder" % scene_name)
		check(not hint.shows_jump, "%s's reminder has no jump button" % scene_name)
		Input.action_press("move_down")
		for frame in 10: await get_tree().process_frame
		check(hint.glow["down"] > 0.5 and hint.glow["up"] == 0.0, "%s: pressing down lights the down arrow" % scene_name)
		Input.action_release("move_down")
		await get_tree().create_timer(0.6).timeout
	var banner_rect = Rect2(Vector2((1920 - 1240) / 2.0, 14), Vector2(1240, 124))
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	hint = get_tree().current_scene.controls_hint
	check(not Rect2(hint.position, hint.size).intersects(banner_rect), "the meadow reminder is clear of the task banner: %s" % Rect2(hint.position, hint.size))
