@abstract
class_name HillsSuite
extends GameSuite
# Base for suites that play Rainbow Hills levels the way a child would: holding right and pressing jump
# at steps and gaps.

const Levels = preload("res://hills/hills_levels.gd")
const PaintPotScript = preload("res://hills/paint_pot.gd")

# How many 1/60s physics steps run per frame. Game time and physics stay the same, only the frames between
# them are fewer, which is where a headless run spends its time. 2 is the game drawing at 30fps, and takes
# the slow suites from 36s to 23s. At 4 (15fps) eight levels need the rescue cloud, so don't go higher
# without looking at why.
const SPEED := 2

var real_ticks: int
var real_max_steps: int

func before_test() -> void:
	super()
	real_ticks = Engine.physics_ticks_per_second
	real_max_steps = Engine.max_physics_steps_per_frame
	Engine.time_scale = SPEED
	Engine.physics_ticks_per_second = real_ticks * SPEED
	Engine.max_physics_steps_per_frame = real_max_steps * SPEED

func after_test() -> void:
	for action in ["move_left", "move_right", "act"]:
		Input.action_release(action)
	Engine.physics_ticks_per_second = real_ticks
	Engine.max_physics_steps_per_frame = real_max_steps
	await super()

func open_level(level_index: int, difficulty := HillsLevels.EASY) -> Node:
	HillsLevelScript.level_to_play = level_index
	HillsLevelScript.difficulty = difficulty
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	return get_tree().current_scene

func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.25).timeout
	Input.action_release(action)

func hold(action: String, seconds: float) -> void:
	Input.action_press(action)
	await get_tree().create_timer(seconds).timeout
	Input.action_release(action)

# Holds right and jumps whenever the ground just ahead is higher or missing. Gives how many times the
# rescue cloud had to carry the blob.
func play_through(level: Node, seconds_allowed: float, jump_ahead := true) -> int:
	var blob: Node = level.blob
	var ground: Node = level.ground
	Input.action_press("move_right")
	var waited := 0.0
	var rescues := 0
	var was_carried := false
	while not level.is_finished and waited < seconds_allowed:
		if blob.is_being_carried and not was_carried:
			rescues += 1
		was_carried = blob.is_being_carried
		if jump_ahead and blob.is_on_floor():
			var here: float = ground.height_at(blob.position.x)
			var ahead: float = ground.height_at(blob.position.x + 110)
			if ahead == INF or ahead < here - 20:
				await tap("act")
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	Input.action_release("move_right")
	return rescues

# Medium has wider gaps, swaying balloons and obstacles. This player waits until near the edge of a gap
# and holds jump for the full distance, jumps obstacles, and turns back (up to three times) for a balloon
# it swept past without popping.
func play_through_medium(level: Node, seconds_allowed: float) -> int:
	var blob: Node = level.blob
	var ground: Node = level.ground
	var obstacles_x: Array = level.get_children().filter(func(c): return _is_script(c, "res://hills/hills_obstacle.gd")) \
		.map(func(o): return o.position.x)
	var balloons: Array = level.effects_layer.get_children().filter(func(c): return _is_script(c, "res://hills/letter_balloon.gd"))
	var tries_back := {}
	var going_back_for: Node = null
	var direction := 1
	Input.action_press("move_right")
	var waited := 0.0
	var rescues := 0
	var was_carried := false
	while not level.is_finished and waited < seconds_allowed:
		if blob.is_being_carried and not was_carried:
			rescues += 1
		was_carried = blob.is_being_carried
		# A popped balloon is freed, and a freed one compares equal to null, so check it each frame
		if is_instance_valid(going_back_for) and blob.position.x < going_back_for.anchor.x - going_back_for.sway_distance - 120:
			going_back_for = null
		if not is_instance_valid(going_back_for):
			going_back_for = null
			for balloon in balloons:
				if is_instance_valid(balloon) and balloon.anchor.x < blob.position.x - 250 and tries_back.get(balloon, 0) < 3:
					going_back_for = balloon
					tries_back[balloon] = tries_back.get(balloon, 0) + 1
					break
		var wanted_direction := -1 if going_back_for != null else 1
		if wanted_direction != direction:
			direction = wanted_direction
			Input.action_release("move_right" if direction < 0 else "move_left")
			Input.action_press("move_left" if direction < 0 else "move_right")
		if blob.is_on_floor():
			var here: float = ground.height_at(blob.position.x)
			var ahead: float = ground.height_at(blob.position.x + 110 * direction)
			var gap_close: bool = ground.height_at(blob.position.x + 50 * direction) == INF
			var obstacle_ahead := obstacles_x.any(func(x): return (x - blob.position.x) * direction > 60 and (x - blob.position.x) * direction < 130)
			if gap_close:
				await hold("act", 0.5)
			elif (ahead != INF and ahead < here - 20) or obstacle_ahead:
				await tap("act")
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	Input.action_release("move_right")
	Input.action_release("move_left")
	return rescues

func find_pots(level: Node) -> Array:
	return level.effects_layer.get_children().filter(func(child): return child.get_script() == PaintPotScript)

func _is_script(node: Node, path: String) -> bool:
	return node.get_script() != null and node.get_script().resource_path == path
