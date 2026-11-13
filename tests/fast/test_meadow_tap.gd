extends GameSuite
# A child tapping the D-pad in the real meadow: puddles shouldn't drag the blob back.

func tap(action):
	Input.action_press(action)
	for frame in 8: await get_tree().physics_frame
	Input.action_release(action)

func test_meadow_tap() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var meadow = get_tree().current_scene
	var blob = meadow.blob
	var puddle = meadow.puddles["blue"]
	blob.position = puddle.position
	blob.velocity = Vector2.ZERO
	for frame in 30: await get_tree().physics_frame

	await tap("move_up")
	for frame in 60: await get_tree().physics_frame
	var after_one_tap = blob.position.distance_to(puddle.position)
	check(after_one_tap > 20, "one tap up off a puddle stays off it: %.0f px away" % after_one_tap)

	await tap("move_up")
	for frame in 60: await get_tree().physics_frame
	var after_two_taps = blob.position.distance_to(puddle.position)
	check(after_two_taps > after_one_tap + 20, "a second tap goes further still: %.0f px away" % after_two_taps)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://meadow_tap_check.json"))
