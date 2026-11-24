extends GameSuite
# Medium's flying letters can be caught on the D-pad alone, with no magnet: eight directions, always pressing
# the one nearest to the letter wanted next. Guards the loop size and speed against becoming a chase.

const SECONDS_PER_WORD: float = 60.0
const DIRECTIONS: Dictionary = {"move_right": Vector2.RIGHT, "move_left": Vector2.LEFT, "move_down": Vector2.DOWN, "move_up": Vector2.UP}

func test_a_long_word_can_be_spelled_on_the_d_pad(word: String, test_parameters := [
	["SANDWICH"], ["KANGAROO"], ["SPLASH"],
]) -> void:
	MeadowScript.difficulty = TaskRunner.MEDIUM
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	var meadow = get_tree().current_scene
	var runner: TaskRunner = meadow.task_runner
	runner.clear_the_grass()
	runner.current_task = MeadowTask.from_dictionary({"type": "spell", "word": word, "text": "?"})
	runner.put_things_in_the_grass()
	await frames(30)
	var frames_left: int = int(SECONDS_PER_WORD * 60)
	while not runner.is_between_tasks and frames_left > 0:
		var wanted: String = word[runner.current_task.letters_done]
		var stones: Array = runner.things_in_the_grass.filter(func(thing): return is_instance_valid(thing) and thing is LetterStone and not thing.is_leaving and thing.value == wanted)
		if not stones.is_empty():
			press_towards(stones[0].position - meadow.blob.position)
		await get_tree().physics_frame
		frames_left -= 1
	for action in DIRECTIONS:
		Input.action_release(action)
	check(runner.is_between_tasks, "%s spelled on the D-pad in %ds: %d letters" % [word, SECONDS_PER_WORD, runner.current_task.letters_done])

# The D-pad direction nearest to the way to go: one of eight
func press_towards(way: Vector2) -> void:
	var octant: float = round(way.angle() / (PI / 4.0)) * (PI / 4.0)
	var pad: Vector2 = Vector2.from_angle(octant)
	for action in DIRECTIONS:
		if pad.dot(DIRECTIONS[action]) > 0.5:
			Input.action_press(action)
		else:
			Input.action_release(action)
