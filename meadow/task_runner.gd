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

const EASY: String = "easy"
const MEDIUM: String = "medium"
const TASKS_PATH: String = "res://data/tasks.json"
## Medium's own cards, not the Easy ones made harder.
const MEDIUM_TASKS_PATH: String = "res://data/tasks_medium.json"
const SECONDS_BETWEEN_TASKS: float = 2.6
## "Drive through the red paint" then "Now wash in the fountain": a new game
## starts with these two, and the wash only ever follows the red paint.
## Easy only: Medium's first two cards are ordinary cards.
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

## EASY or MEDIUM. Set before the runner joins the tree.
var difficulty: String = EASY## Medium's flying letters start here: the roomiest spots, apart from each
## other, for a figure of eight that clears the rainbow, pots, puddles,
## fountain and bushes (found by search, .tmp_test/probe_flying_spots.gd).
## Ten: eight for Medium's longest words, and two spare for when the blob is
## in the way. The meadow is crowded, so most loops are smaller than 90.
const FLYING_SPOTS: Array[Vector2] = [
	Vector2(1630, 460), Vector2(450, 400), Vector2(1450, 360), Vector2(190, 840), Vector2(1650, 840),
	Vector2(250, 400), Vector2(1190, 840), Vector2(730, 840), Vector2(430, 600), Vector2(1490, 620),
]
## A free spot this close to a flying spot is too close to use as well.
const ROOM_BETWEEN_SPOTS: float = 150.0

var tasks: Array[MeadowTask] = []
var current_task: MeadowTask
var is_between_tasks: bool = false
var things_in_the_grass: Array[Node2D] = []
var grass_layer: Node2D
var effects_layer: Node2D
var banner: TaskBanner
## The blob, so new stones and drops keep away from it. Can be left null.
var blob_to_keep_clear_of: Node2D
## Medium: every letter rides a butterfly. Numbers and drops stay put.
var letters_fly: bool = false
## What a flying letter's loop keeps clear of: {"centre", "radius"} each.
var places_to_keep_clear: Array[Dictionary] = []
var loop_size_at: Dictionary = {}


func _init(layer_for_stones: Node2D, layer_for_effects: Node2D, task_banner: TaskBanner) -> void:
	grass_layer = layer_for_stones
	effects_layer = layer_for_effects
	banner = task_banner


func _ready() -> void:
	tasks = MeadowTask.load_list(MEDIUM_TASKS_PATH if is_medium() else TASKS_PATH)
	if tasks.is_empty():
		return
	start_task(GameSettings.get_progress(next_task_progress_name()) % tasks.size())


func is_medium() -> bool:
	return difficulty == MEDIUM


## Each difficulty keeps its own next card and deck.
func next_task_progress_name() -> String:
	return "next_task_index_medium" if is_medium() else "next_task_index"


func saved_deck() -> Array[int]:
	return GameSettings.get_medium_task_deck() if is_medium() else GameSettings.get_task_deck()


func save_deck(deck: Array[int]) -> void:
	if is_medium():
		GameSettings.set_medium_task_deck(deck)
	else:
		GameSettings.set_task_deck(deck)


## Easy teaches the game with the red paint then the wash. Medium doesn't.
func has_wash_lesson() -> bool:
	return not is_medium()


## Medium opens once Easy has dealt every card once, or early if a grown-up
## has switched "Open Medium" on (it opens the Hills' Medium too).
static func is_medium_unlocked() -> bool:
	if GameSettings.get_setting("open_hills_medium") == 1:
		return true
	return GameSettings.get_progress("tasks_completed") >= MeadowTask.load_list(TASKS_PATH).size()


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
## comes straight after the red paint and is never dealt on its own (Easy only).
func deal_next_task_index(current_task_index: int) -> int:
	if tasks.size() <= 1:
		return 0
	if has_wash_lesson() and current_task_index == RED_PAINT_TASK_INDEX:
		return WASH_TASK_INDEX
	var deck: Array[int] = saved_deck().filter(
		func(task_index: int) -> bool: return task_index < tasks.size() and task_index != current_task_index and not is_the_wash(task_index))
	if deck.is_empty():
		deck = new_shuffled_deck(current_task_index)
	var next_task_index: int = deck.pop_back()
	save_deck(deck)
	return next_task_index


func is_the_wash(task_index: int) -> bool:
	return has_wash_lesson() and task_index == WASH_TASK_INDEX


## Leaves out the task just played and the wash. Straight after the wash it
## also leaves out the red paint, which was just played too.
func new_shuffled_deck(task_index_just_played: int) -> Array[int]:
	var deck: Array[int] = []
	for task_index in tasks.size():
		var was_just_played: bool = task_index == task_index_just_played
		var is_the_wash_pair_just_played: bool = is_the_wash(task_index_just_played) and task_index == RED_PAINT_TASK_INDEX
		if not was_just_played and not is_the_wash(task_index) and not is_the_wash_pair_just_played:
			deck.append(task_index)
	deck.shuffle()
	return deck


func put_things_in_the_grass() -> void:
	var spots: Array[Vector2]
	if letters_fly and has_letters():
		spots = spots_for_flying_letters()
	else:
		spots = spots_away_from_the_blob(FREE_SPOTS)
		spots.shuffle()
	var delay: float = 0.4
	for value in current_task.stone_values():
		var stone: LetterStone = LetterStone.new()
		stone.value = value
		stone.paint_colour = PaintColours.RAINBOW[things_in_the_grass.size() % PaintColours.RAINBOW.size()]
		stone.position = spots.pop_back()
		stone.blob_entered.connect(on_stone_entered)
		if letters_fly and is_a_letter(value):
			give_wings(stone)
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


static func is_a_letter(value: String) -> bool:
	return value.to_upper() != value.to_lower()


## A butterfly behind it and a figure of eight to fly round where it was put.
func give_wings(stone: LetterStone) -> void:
	var butterfly: Butterfly = Butterfly.new()
	butterfly.colour = stone.paint_colour
	stone.add_child(butterfly)
	var flight: LetterFlight = LetterFlight.new(stone.position, places_to_keep_clear)
	stone.add_child(flight)
	stone.position = flight.start_position()


func has_letters() -> bool:
	return current_task.stone_values().any(is_a_letter)


## The flying spots, shuffled, dealt first (from the end). If the blob is in
## the way of some, free spots that aren't near a flying spot come before
## them, the roomiest last.
func spots_for_flying_letters() -> Array[Vector2]:
	var flying: Array[Vector2] = spots_away_from_the_blob(FLYING_SPOTS)
	flying.shuffle()
	var fallback: Array[Vector2] = spots_away_from_the_blob(FREE_SPOTS).filter(func(spot: Vector2) -> bool:
		return FLYING_SPOTS.all(func(flying_spot: Vector2) -> bool: return spot.distance_to(flying_spot) >= ROOM_BETWEEN_SPOTS))
	fallback.sort_custom(func(a: Vector2, b: Vector2) -> bool: return room_to_fly(a) < room_to_fly(b))
	return fallback + flying


## How big a loop fits at a spot. Remembered: the meadow doesn't change.
func room_to_fly(spot: Vector2) -> float:
	if not loop_size_at.has(spot):
		loop_size_at[spot] = LetterFlight.fitted_loop(spot, places_to_keep_clear).size
	return loop_size_at[spot]


func spots_away_from_the_blob(all_spots: Array[Vector2] = FREE_SPOTS) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for spot in all_spots:
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


func allows_pot(paint_name: String, next_empty_pot: String) -> bool:
	return current_task == null or is_between_tasks or current_task.allows_pot(paint_name, next_empty_pot)


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
		if result == "progress":
			pick_the_next_letter_under_the_blob.call_deferred()
	if result == "done" and current_task.type == "spell" and current_task.thing != "":
		word_came_to_life.emit(current_task.thing, stone.position)
	if result == "done" and current_task.type == "change":
		thing_changed.emit(current_task.from_word.to_lower(), current_task.thing)
	banner.queue_redraw()


## A stone only notices the blob driving on. If the next letter is already
## under it (turned away a moment ago, or a flying letter that looped in),
## it's picked now, without driving off and back on.
func pick_the_next_letter_under_the_blob() -> void:
	if blob_to_keep_clear_of == null or current_task.type != "spell" or is_between_tasks:
		return
	var wanted: String = current_task.word[current_task.letters_done]
	for thing in things_in_the_grass:
		if is_instance_valid(thing) and thing is LetterStone and not thing.is_leaving \
				and thing.value == wanted and thing.overlaps_body(blob_to_keep_clear_of):
			on_stone_entered(thing)
			return


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
	var next_index: int = deal_next_task_index(GameSettings.get_progress(next_task_progress_name()))
	GameSettings.record_progress(next_task_progress_name(), next_index)
	task_finished.emit()
	clear_the_grass()
	await get_tree().create_timer(SECONDS_BETWEEN_TASKS, false).timeout
	banner.hide_task()
	await get_tree().create_timer(0.5, false).timeout
	start_task(next_index)
