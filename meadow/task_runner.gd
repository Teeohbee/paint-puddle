class_name TaskRunner
extends Node
## Works through the task pack one card at a time, in a shuffled order. Puts
## letter stones and paint drops in the grass for the current task, passes it
## what happens in the meadow, and cheers when it's done before moving on.

signal task_finished
## A spelled word turning into its thing, where the last letter was.
signal word_came_to_life(thing_name: String, at: Vector2)
signal task_started(task: MeadowTask)
## A change task done: the thing for the old word turns into the new one.
signal thing_changed(from_name: String, to_name: String)

const TASKS_PATH: String = "res://data/tasks.json"
const SECONDS_BETWEEN_TASKS: float = 2.6
## "Drive through the red paint" then "Now wash in the fountain": a new game
## starts with these two, and the wash only ever follows the red paint.
const RED_PAINT_TASK_INDEX: int = 0
const WASH_TASK_INDEX: int = 1
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
## The number stack trailing behind the blob in a join task, if any.
var carried_stack: NumberStack
## What's left after taking away, its number hidden until it's counted.
var split_remainder: NumberStack


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
	task_started.emit(current_task)
	put_things_in_the_grass()


## The next task, in a mixed-up order: tasks are dealt from a shuffled deck,
## so every task comes up once before any comes round again. The deck is
## saved. A new deck never starts with the task just played. The first two
## tasks teach the game (red paint, then wash it off), so the wash always
## comes straight after the red paint and is never dealt on its own.
func deal_next_task_index(current_task_index: int) -> int:
	if tasks.size() <= 1:
		return 0
	if current_task_index == RED_PAINT_TASK_INDEX:
		return WASH_TASK_INDEX
	var deck: Array[int] = GameSettings.get_task_deck().filter(
		func(task_index: int) -> bool: return task_index < tasks.size() and task_index != current_task_index and task_index != WASH_TASK_INDEX)
	if deck.is_empty():
		deck = new_shuffled_deck(current_task_index)
	var next_task_index: int = deck.pop_back()
	GameSettings.set_task_deck(deck)
	return next_task_index


## Leaves out the task just played and the wash. Straight after the wash it
## also leaves out the red paint, which was just played too.
func new_shuffled_deck(task_index_just_played: int) -> Array[int]:
	var deck: Array[int] = []
	for task_index in tasks.size():
		var was_just_played: bool = task_index == task_index_just_played
		var is_the_wash_pair_just_played: bool = task_index_just_played == WASH_TASK_INDEX and task_index == RED_PAINT_TASK_INDEX
		if not was_just_played and task_index != WASH_TASK_INDEX and not is_the_wash_pair_just_played:
			deck.append(task_index)
	deck.shuffle()
	return deck


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
	if current_task.type == "split":
		var whole: NumberStack = NumberStack.new()
		whole.value = current_task.start_number
		whole.position = spots.pop_back()
		whole.blob_entered.connect(on_stack_entered)
		add_to_grass(whole, delay)
	if current_task.type == "join":
		for stack_value in current_task.stacks:
			var stack: NumberStack = NumberStack.new()
			stack.value = stack_value
			stack.position = spots.pop_back()
			stack.blob_entered.connect(on_stack_entered)
			add_to_grass(stack, delay)
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


## The first stack driven into follows the blob. The next one joins it:
## exactly right finishes the task, too big wobbles and they come apart,
## and too small makes a bigger stack that keeps following.
func on_stack_entered(stack: NumberStack) -> void:
	if current_task == null or is_between_tasks:
		return
	if current_task.type == "split":
		# Not in the middle of the collision: splitting adds a new stack
		split_stack.call_deferred(stack)
		return
	if carried_stack == null or not is_instance_valid(carried_stack):
		carried_stack = stack
		stack.follow(blob_to_keep_clear_of)
		Sound.play("pick", 0.0, 0.9 + stack.value * 0.04)
		return
	# Finishing the task clears the grass (and carried_stack), so hold on to it here
	var held_stack: NumberStack = carried_stack
	var total: int = held_stack.value + stack.value
	var result: String = handle({"kind": "stacks_joined", "total": total})
	if result == "wrong":
		stack.wobble()
		held_stack.put_down()
		held_stack.wobble()
		carried_stack = null
		Sound.play("wobble", 0.0)
		FloatingText.show_at(effects_layer, stack.position - Vector2(0, 90), "%d is too many!" % total, PaintColours.INK, 52)
		return
	Sound.play("pop", 0.0, 0.8 + total * 0.05)
	PaintSplash.burst(effects_layer, stack.position, NumberStack.square_colour(total, 0), 14, 450)
	FloatingText.show_at(effects_layer, stack.position - Vector2(0, total * 30 + 40), "%d and %d make %d" % [held_stack.value, stack.value, total],
		PaintColours.INK, 52, 1.6)
	held_stack.leave()
	stack.value = total
	carried_stack = null
	if result == "done":
		stack.arrangement = current_task.finished_arrangement()
	if result == "progress":
		stack.hop()
		carried_stack = stack
		stack.follow(blob_to_keep_clear_of)


## Take away: the taken part hops off and goes, what's left loses its
## number so it can be counted, and stones ask how many are left.
func split_stack(stack: NumberStack) -> void:
	if current_task.has_split:
		return
	handle({"kind": "stack_split"})
	var taken: NumberStack = NumberStack.new()
	taken.value = current_task.take_away
	taken.position = stack.position
	grass_layer.add_child(taken)
	taken.set_deferred("monitoring", false)
	var hop_off: Tween = taken.create_tween()
	hop_off.tween_property(taken, "position", stack.position + Vector2(120, -60), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop_off.tween_interval(0.8)
	hop_off.tween_callback(taken.leave)
	stack.value = current_task.start_number - current_task.take_away
	stack.shows_number = false
	stack.set_deferred("monitoring", false)
	split_remainder = stack
	stack.hop()
	Sound.play("pop", 0.0, 0.9)
	FloatingText.show_at(effects_layer, stack.position - Vector2(0, 120), "Take away %d" % current_task.take_away, PaintColours.INK, 56, 1.6)
	var spots: Array[Vector2] = []
	for spot in spots_away_from_the_blob():
		if spot.distance_to(stack.position) > 160.0:
			spots.append(spot)
	spots.shuffle()
	var delay: float = 0.6
	for choice in current_task.split_choices():
		var choice_stone: LetterStone = LetterStone.new()
		choice_stone.value = str(choice)
		choice_stone.paint_colour = PaintColours.RAINBOW[things_in_the_grass.size() % PaintColours.RAINBOW.size()]
		choice_stone.position = spots.pop_back()
		choice_stone.blob_entered.connect(on_stone_entered)
		add_to_grass(choice_stone, delay)
		delay += 0.08
	banner.queue_redraw()


func clear_the_grass() -> void:
	for thing in things_in_the_grass:
		if is_instance_valid(thing) and not thing.is_leaving:
			thing.leave()
	things_in_the_grass.clear()
	carried_stack = null


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
	if result == "done" and split_remainder != null and is_instance_valid(split_remainder):
		split_remainder.shows_number = true
		split_remainder.queue_redraw()
		split_remainder = null
	if result == "wrong":
		stone.wobble()
		Sound.play("wobble", 0.0)
	elif result == "progress" or result == "done":
		Sound.play("pop", 0.0, 1.0 + current_task.letters_done * 0.07)
		PaintSplash.burst(effects_layer, stone.position, stone.paint_colour, 12, 420)
		stone.leave()
	if result == "done" and current_task.type == "spell" and current_task.thing != "":
		word_came_to_life.emit(current_task.thing, stone.position)
	if result == "done" and current_task.type == "change":
		thing_changed.emit(current_task.from_word.to_lower(), current_task.thing)
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
	var next_index: int = deal_next_task_index(GameSettings.get_progress("next_task_index"))
	GameSettings.record_progress("next_task_index", next_index)
	task_finished.emit()
	clear_the_grass()
	await get_tree().create_timer(SECONDS_BETWEEN_TASKS, false).timeout
	banner.hide_task()
	await get_tree().create_timer(0.5, false).timeout
	start_task(next_index)
