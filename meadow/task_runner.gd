class_name TaskRunner
extends Node
## Works through the task pack one card at a time. Puts letter stones and
## paint drops in the grass for the current task, passes it what happens in
## the meadow, and cheers when it's done before moving on.

signal task_finished

const TASKS_PATH: String = "res://data/tasks.json"
const SECONDS_BETWEEN_TASKS: float = 2.6
## Nothing new appears this close to the blob, or it would be picked for free.
const CLEAR_DISTANCE_FROM_BLOB: float = 150.0
## Clear patches of grass where stones and drops can go.
const FREE_SPOTS: Array[Vector2] = [
	Vector2(200, 420), Vector2(1720, 450), Vector2(715, 800), Vector2(1205, 800),
	Vector2(200, 900), Vector2(1720, 900), Vector2(430, 200), Vector2(1490, 200),
	Vector2(440, 430), Vector2(1480, 430), Vector2(960, 450), Vector2(420, 690),
	Vector2(1500, 690), Vector2(200, 760), Vector2(1720, 760),
]

var tasks: Array[MeadowTask] = []
var current_task: MeadowTask
var is_between_tasks: bool = false
var things_in_the_grass: Array[Node2D] = []
var grass_layer: Node2D
var effects_layer: Node2D
var banner: TaskBanner
## The blob, so new stones and drops keep away from it. Can be left null.
var blob_to_keep_clear_of: Node2D


func _init(layer_for_stones: Node2D, layer_for_effects: Node2D, task_banner: TaskBanner) -> void:
	grass_layer = layer_for_stones
	effects_layer = layer_for_effects
	banner = task_banner


func _ready() -> void:
	tasks = MeadowTask.load_list(TASKS_PATH)
	if tasks.is_empty():
		return
	start_task(GameSettings.get_progress("next_task_index") % tasks.size())


func start_task(task_index: int) -> void:
	current_task = tasks[task_index].fresh_copy()
	banner.show_task(current_task)
	is_between_tasks = false
	put_things_in_the_grass()


func put_things_in_the_grass() -> void:
	var spots: Array[Vector2] = spots_away_from_the_blob()
	spots.shuffle()
	var delay: float = 0.4
	for value in current_task.stone_values():
		var stone: LetterStone = LetterStone.new()
		stone.value = value
		stone.paint_colour = PaintColours.RAINBOW[things_in_the_grass.size() % PaintColours.RAINBOW.size()]
		stone.position = spots.pop_back()
		stone.blob_entered.connect(on_stone_entered)
		add_to_grass(stone, delay)
		delay += 0.08
	if current_task.type == "collect":
		var distractor_paint: String = "red" if current_task.paint != "red" else "blue"
		for drop_index in current_task.count + MeadowTask.DISTRACTOR_DROP_COUNT:
			var drop: PaintDrop = PaintDrop.new()
			drop.paint_name = current_task.paint if drop_index < current_task.count else distractor_paint
			drop.position = spots.pop_back()
			drop.blob_entered.connect(on_drop_entered)
			add_to_grass(drop, delay)
			delay += 0.08


func spots_away_from_the_blob() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for spot in FREE_SPOTS:
		var is_near_the_blob: bool = blob_to_keep_clear_of != null \
			and spot.distance_to(blob_to_keep_clear_of.position) < CLEAR_DISTANCE_FROM_BLOB
		if not is_near_the_blob:
			spots.append(spot)
	return spots


func add_to_grass(thing: Node2D, delay: float) -> void:
	grass_layer.add_child(thing)
	thing.pop_in(delay)
	things_in_the_grass.append(thing)


func clear_the_grass() -> void:
	for thing in things_in_the_grass:
		if is_instance_valid(thing) and not thing.is_leaving:
			thing.leave()
	things_in_the_grass.clear()


## Everything the meadow tells the task goes through here.
func handle(event: Dictionary) -> String:
	if current_task == null or is_between_tasks:
		return "ignored"
	var result: String = current_task.handle(event)
	if result == "done":
		finish_task()
	return result


func on_stone_entered(stone: LetterStone) -> void:
	var result: String = handle({"kind": "stone", "value": stone.value})
	if result == "wrong":
		stone.wobble()
		Sound.play("wobble", 0.0)
	elif result == "progress" or result == "done":
		Sound.play("pop", 0.0, 1.0 + current_task.letters_done * 0.07)
		PaintSplash.burst(effects_layer, stone.position, stone.paint_colour, 12, 420)
		stone.leave()
	banner.queue_redraw()


func on_drop_entered(drop: PaintDrop) -> void:
	var result: String = handle({"kind": "drop", "paint": drop.paint_name})
	if result == "wrong":
		drop.wobble()
		Sound.play("wobble", 0.0)
	elif result == "progress" or result == "done":
		Sound.play("plop", 0.0, 0.9 + current_task.collected * 0.06)
		FloatingText.show_at(effects_layer, drop.position - Vector2(0, 40), str(current_task.collected),
			PaintMixing.colour_of(drop.paint_name).darkened(0.2), 72)
		drop.leave()
	banner.queue_redraw()


func finish_task() -> void:
	is_between_tasks = true
	banner.celebrate()
	Sound.play("chime", 0.0)
	FloatingText.show_at(effects_layer, Vector2(960, 420), "Well done!", PaintColours.PURPLE, 130, 2.0, 60.0)
	var confetti: Confetti = Confetti.new()
	effects_layer.add_child(confetti)
	GameSettings.record_progress("tasks_completed", GameSettings.get_progress("tasks_completed") + 1)
	var next_index: int = (GameSettings.get_progress("next_task_index") + 1) % tasks.size()
	GameSettings.record_progress("next_task_index", next_index)
	task_finished.emit()
	clear_the_grass()
	await get_tree().create_timer(SECONDS_BETWEEN_TASKS, false).timeout
	banner.hide_task()
	await get_tree().create_timer(0.5, false).timeout
	start_task(next_index)
