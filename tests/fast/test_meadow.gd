extends GameSuite

func hold(actions, seconds):
	for action in actions: Input.action_press(action)
	await get_tree().create_timer(seconds).timeout
	for action in actions: Input.action_release(action)

func test_meadow() -> void:
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var blob = get_tree().current_scene.blob
	var start = blob.position
	await hold(["move_up"], 0.5)
	check(blob.position.y < start.y - 100, "up moves the blob up: " + str(blob.position))

	await hold(["move_up"], 3.0)
	check(blob.position.y > 56 and blob.position.y < 140, "the hedge stops it at the top: " + str(blob.position))

	# Up and right together along the top hedge: it should slide right, not stick
	var x_before = blob.position.x
	await hold(["move_up", "move_right"], 0.8)
	check(blob.position.x > x_before + 120, "it slides along the hedge: %.0f -> %.0f" % [x_before, blob.position.x])

	await hold(["move_down", "move_left"], 8.0)
	check(blob.position.x > 56 and blob.position.y < 1080 - 56, "it never leaves the meadow: " + str(blob.position))
