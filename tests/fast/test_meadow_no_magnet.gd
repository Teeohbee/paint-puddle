extends GameSuite
# Medium has no magnet: letting go near a puddle leaves the blob where it stopped, so steering is all his.
# Easy keeps the gentle pull.

var meadow

func open_meadow(difficulty: String) -> void:
	MeadowScript.difficulty = difficulty
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	meadow = get_tree().current_scene

func let_go_beside_the_red_puddle() -> float:
	var puddle: Node2D = meadow.puddles["red"]
	meadow.blob.position = puddle.position + Vector2(puddle.magnet_radius - 20, 0)
	meadow.blob.velocity = Vector2.ZERO
	var start: float = meadow.blob.position.distance_to(puddle.position)
	await frames(30)
	return start - meadow.blob.position.distance_to(puddle.position)

func test_on_easy_letting_go_near_a_puddle_drifts_onto_it() -> void:
	await open_meadow(TaskRunner.EASY)
	var pulled: float = await let_go_beside_the_red_puddle()
	check(pulled > 20, "Easy pulls the blob in: %.1f" % pulled)

func test_on_medium_letting_go_near_a_puddle_stays_put() -> void:
	await open_meadow(TaskRunner.MEDIUM)
	var pulled: float = await let_go_beside_the_red_puddle()
	check(absf(pulled) < 1.0, "Medium leaves it where it stopped: moved %.1f" % pulled)
	check(not meadow.blob.uses_magnet, "the Medium blob has no magnet")
