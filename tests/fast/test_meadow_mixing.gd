extends GameSuite

var meadow
var blob

func visit(target_position):
	blob.position = Vector2(960, 690)
	await get_tree().physics_frame
	await get_tree().physics_frame
	blob.position = target_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

func test_meadow_mixing() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	check(blob.paint_name == "clean", "the blob starts clean")

	await visit(meadow.puddles["red"].position)
	check(blob.paint_name == "red", "the red puddle paints it red")
	await visit(meadow.puddles["yellow"].position)
	check(blob.paint_name == "orange", "then yellow mixes orange")
	check(meadow.sum_card.result_paint == "orange" and meadow.sum_card.first_paint == "red", "the picture sum shows red + yellow = orange")

	var red_pot = meadow.rainbow.pot_for("red")
	await visit(red_pot.global_position)
	check(not red_pot.is_filled, "orange paint doesn't fill the red pot")
	var orange_pot = meadow.rainbow.pot_for("orange")
	await visit(orange_pot.global_position)
	check(orange_pot.is_filled, "orange paint fills the orange pot")

	await visit(meadow.puddles["blue"].position)
	check(blob.paint_name == "brown", "adding blue to orange makes brown")
	await visit(meadow.fountain.position)
	check(blob.paint_name == "clean", "the fountain washes it clean")

	var rainbows_before = settings.get_progress("rainbows_painted")
	var recipes = {"red": ["red"], "yellow": ["yellow"], "green": ["yellow", "blue"], "blue": ["blue"], "purple": ["red", "blue"]}
	for paint_name in recipes:
		await visit(meadow.fountain.position)
		for puddle_name in recipes[paint_name]:
			await visit(meadow.puddles[puddle_name].position)
		await visit(meadow.rainbow.pot_for(paint_name).global_position)
		check(meadow.rainbow.pot_for(paint_name).is_filled, paint_name + " pot filled")
	await get_tree().create_timer(1.0).timeout
	check(meadow.is_celebrating, "six stripes finish the rainbow and start the celebration")
	check(settings.get_progress("rainbows_painted") == rainbows_before + 1, "the finished rainbow is counted")
	await get_tree().create_timer(6.5).timeout
	check(not meadow.is_celebrating and not meadow.rainbow.pot_for("red").is_filled, "then the rainbow empties, ready to paint again")

	# Magnet: let go just beside a puddle and the blob drifts onto it
	await visit(meadow.fountain.position)
	blob.position = meadow.puddles["blue"].position + Vector2(0, -130)
	blob.velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	check(blob.position.distance_to(meadow.puddles["blue"].position) < 20, "letting go near a puddle drifts onto it: %.0f px away" % blob.position.distance_to(meadow.puddles["blue"].position))
	check(blob.paint_name == "blue", "and picks up its paint")
	blob.position = Vector2(960, 690)
	await get_tree().create_timer(0.5).timeout
	check(blob.position.distance_to(Vector2(960, 690)) < 1.0, "away from everything the blob stays put")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://meadow_mixing_check.json"))
