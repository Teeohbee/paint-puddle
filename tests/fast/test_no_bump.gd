extends GameSuite
# He didn't like the bump: driving into a hedge at full speed should neither
# squash the blob nor play a thud. It just stops and slides along.

func test_no_bump() -> void:
	for scene_path in ["res://meadow/meadow.tscn", "res://paint/paint_studio.tscn"]:
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
		await get_tree().process_frame
		var blob = get_tree().current_scene.blob
		Input.action_press("move_up")
		# Up to full speed first, so the starting squash has settled
		await get_tree().create_timer(0.7).timeout
		var biggest_squash_speed = 0.0
		var started_at = blob.position.y
		for frame in 180:
			await get_tree().physics_frame
			biggest_squash_speed = max(biggest_squash_speed, blob.look.squash_stretch.velocity.length())
		Input.action_release("move_up")
		check(blob.position.y < started_at - 100, "%s: the blob reached the hedge" % scene_path)
		check(biggest_squash_speed < 1.0, "%s: hitting the hedge doesn't squash the blob (%.2f)" % [scene_path, biggest_squash_speed])
		await get_tree().create_timer(0.5).timeout
	check(not Sound.sounds.has("bump"), "there's no bump sound any more")
