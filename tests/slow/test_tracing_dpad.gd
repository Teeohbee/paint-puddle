extends GameSuite
# Every letter can be traced on the D-pad alone: eight directions, always pressing the one nearest to the
# next dot. The house rule is that the whole game plays on the D-pad, so this is what guards the reach.

const SECONDS_PER_LETTER: float = 40.0
const DIRECTIONS: Dictionary = {"move_right": Vector2.RIGHT, "move_left": Vector2.LEFT, "move_down": Vector2.DOWN, "move_up": Vector2.UP}

func test_every_letter_can_be_traced_on_the_d_pad(letter_index: int, test_parameters := [
	[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12],
	[13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25],
]) -> void:
	TracingMode.letter_to_play = letter_index
	get_tree().change_scene_to_file("res://tracing/tracing_mode.tscn")
	await frames(3)
	var mode: TracingMode = get_tree().current_scene
	var frames_left: int = int(SECONDS_PER_LETTER * 60)
	while not mode.progress.is_finished() and frames_left > 0:
		press_towards(mode.progress.next_dot() - mode.blob.position)
		await get_tree().physics_frame
		frames_left -= 1
	for action in DIRECTIONS:
		Input.action_release(action)
	check(mode.progress.is_finished(), "%s traced on the D-pad in %ds: %d of its dots painted" % [
		mode.letter, SECONDS_PER_LETTER, mode.progress.painted_count()])

# The D-pad direction nearest to the way to go: one of eight
func press_towards(way: Vector2) -> void:
	var octant: float = round(way.angle() / (PI / 4.0)) * (PI / 4.0)
	var pad: Vector2 = Vector2.from_angle(octant)
	for action in DIRECTIONS:
		if pad.dot(DIRECTIONS[action]) > 0.5:
			Input.action_press(action)
		else:
			Input.action_release(action)
