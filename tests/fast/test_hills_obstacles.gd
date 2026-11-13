extends GameSuite

func is_script(node, path): return node.get_script() != null and node.get_script().resource_path == path

func test_hills_obstacles() -> void:
	await get_tree().process_frame
	var levels = load("res://hills/hills_levels.gd")
	var placer = load("res://hills/hills_obstacles.gd")
	var level_script = load("res://hills/hills_level.gd")
	var total = 0
	var empty_levels = 0
	var planned = []
	for level_index in levels.level_count():
		var ground = load("res://hills/hills_ground.gd").new()
		get_tree().root.add_child(ground)
		ground.build(levels.LEVELS[level_index].pieces, 1.0)
		var first = placer.place(ground, level_index)
		var again = placer.place(ground, level_index)
		check(first == again, "level %d placement is repeatable" % (level_index + 1))
		planned.append(first)
		var name = levels.LEVELS[level_index].name
		if first.is_empty(): empty_levels += 1
		total += first.size()
		for i in first.size():
			var x = first[i]
			check(x >= 700 and x <= ground.level_length - 500, "%s: obstacle %d clear of start and flag" % [name, i])
			var here = ground.height_at(x)
			check(here != INF, "%s: obstacle %d on solid ground" % [name, i])
			for d in range(-200, 251, 10):
				var h = ground.height_at(x + d)
				check(h != INF and absf(h - here) <= 2.0, "%s: obstacle %d has flat ground %d away" % [name, i, d])
			if i > 0:
				check(x - first[i - 1] >= 700, "%s: obstacles %d spaced" % [name, i])
		ground.queue_free()
	print("obstacles in total: %d, levels with none: %d" % [total, empty_levels])
	# Only levels with no flat room at all go without (2 and 5 today)
	check(empty_levels <= 2, "at most 2 levels with no room for obstacles: %d" % empty_levels)

	# In game: balloons don't push obstacles away, they float above them
	level_script.difficulty = "medium"
	var lifted_total = 0
	for level_index in levels.level_count():
		level_script.level_to_play = level_index
		get_tree().change_scene_to_file("res://hills/hills_level.tscn")
		await get_tree().process_frame
		await get_tree().process_frame
		var level = get_tree().current_scene
		var obstacles = level.get_children().filter(func(c): return is_script(c, "res://hills/hills_obstacle.gd"))
		check(obstacles.size() == planned[level_index].size(), "level %d gets all %d planned obstacles in game: %d" % [level_index + 1, planned[level_index].size(), obstacles.size()])
		for balloon in level.effects_layer.get_children().filter(func(c): return is_script(c, "res://hills/letter_balloon.gd")):
			var height = level.ground.height_at(balloon.anchor.x) - balloon.anchor.y
			var over = obstacles.any(func(o): return absf(o.position.x - balloon.anchor.x) < balloon.sway_distance + level_script.BALLOON_OVER_OBSTACLE_REACH)
			if over:
				lifted_total += 1
				# balloon bottom (radius 44, bobs 8) clear of the tallest obstacle (snowball, top 76 up)
				check(height - 44 - 8 > 76, "level %d: balloon %s over an obstacle is lifted clear: %d" % [level_index + 1, balloon.letter, height])
				check(height < level_script.PAINT_POT_HEIGHT_ABOVE_GROUND, "level %d: lifted balloon %s still in jump reach: %d" % [level_index + 1, balloon.letter, height])
			else:
				check(is_equal_approx(height, level_script.BALLOON_HEIGHT_ABOVE_GROUND), "level %d: balloon %s away from obstacles stays put: %d" % [level_index + 1, balloon.letter, height])
	print("balloons lifted over obstacles: %d" % lifted_total)
	check(lifted_total > 0, "some balloons are lifted over obstacles")

	# the bump
	level_script.level_to_play = 0
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var level = get_tree().current_scene
	var obstacles = level.get_children().filter(func(c): return is_script(c, "res://hills/hills_obstacle.gd"))
	check(obstacles.size() > 0, "medium level 1 has obstacles: %d" % obstacles.size())
	if obstacles.size() > 0:
		var o = obstacles[0]
		var blob = level.blob
		blob.position = o.position + Vector2(-60, -RADIUS_OFFSET())
		await get_tree().create_timer(0.5).timeout
		check(blob.position.x < o.position.x - 100, "bumped back to the left: %f vs %f" % [blob.position.x, o.position.x])
		check(not level.is_finished and level.players[0].blob.can_move, "still playing after a bump")

func RADIUS_OFFSET(): return 46.0
