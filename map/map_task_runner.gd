class_name MapTaskRunner
extends Node
## Deals Map mode's tasks and judges the answers. "Find France." starts on the
## world screen: the soft arrow points at Europe, then at France once he is
## inside. A wrong country, or the wrong continent, gets a kind word and
## nothing is taken away. Finding it paints the country, saves it, and
## starts the next one back on the world screen.

signal task_started(task: MapTask)
signal task_finished(task: MapTask)

## The arrow shows after this many wrong tries, or this long with no luck.
## 0 seconds would show it all the time.
const HINT_AFTER_WRONG_TRIES: int = 2
const HINT_AFTER_SECONDS: float = 25.0
const SECONDS_TO_CELEBRATE: float = 2.6
const MESSAGE_SECONDS: float = 2.6
## A brand new game opens on one of these: big and hard to miss.
const STARTER_COUNTRIES: Array[String] = ["australia", "usa", "brazil", "china", "india", "canada"]
## The first round deals countries roughly biggest first, shuffled within bands this wide,
## so it eases from the easy ones into the tiny ones without being the same every time.
const EASING_BAND_SIZE: int = 12

var mode: MapMode
var tasks: Array[MapTask] = []
var current_task: MapTask
var current_task_index: int = -1
var wrong_tries: int = 0
var seconds_on_task: float = 0.0
var is_between_tasks: bool = false


func _init(map_mode: MapMode) -> void:
	mode = map_mode


func _ready() -> void:
	tasks = MapTask.load_list()
	mode.country_picked.connect(on_country_picked)
	mode.continent_entered.connect(on_continent_entered)
	if not tasks.is_empty():
		start_task(first_task_index())


func start_task(task_index: int) -> void:
	current_task_index = task_index
	current_task = tasks[task_index]
	wrong_tries = 0
	seconds_on_task = 0.0
	is_between_tasks = false
	mode.task_banner.show_task(current_task)
	task_started.emit(current_task)


## A brand new game (nothing found, no deck yet) opens on a starter country; otherwise
## the next task from the saved deck, as ever.
func first_task_index() -> int:
	var is_brand_new: bool = GameSettings.found_in("countries_found").is_empty() and GameSettings.get_map_task_deck().is_empty()
	if not is_brand_new:
		return deal_next_task_index(-1)
	var starters: Array[int] = []
	for task_index in tasks.size():
		if STARTER_COUNTRIES.has(tasks[task_index].country_id) and tasks[task_index].thing == "":
			starters.append(task_index)
	if starters.is_empty():
		return deal_next_task_index(-1)
	var starter: int = starters.pick_random()
	GameSettings.set_map_task_deck(new_shuffled_deck(starter))
	return starter


## The next task, in a mixed-up order: dealt from a shuffled deck, so every
## task comes up once before any comes round again. The deck is saved, and a
## new deck never starts with the task just played.
func deal_next_task_index(index_just_played: int) -> int:
	if tasks.size() <= 1:
		return 0
	var deck: Array[int] = GameSettings.get_map_task_deck().filter(
		func(task_index: int) -> bool: return task_index < tasks.size() and task_index != index_just_played)
	if deck.is_empty():
		deck = new_shuffled_deck(index_just_played)
	var next_task_index: int = deck.pop_back()
	GameSettings.set_map_task_deck(deck)
	return next_task_index


func new_shuffled_deck(index_just_played: int) -> Array[int]:
	var deck: Array[int] = []
	for task_index in tasks.size():
		if task_index != index_just_played:
			deck.append(task_index)
	if GameSettings.found_in("countries_found").is_empty():
		return eased(deck)
	deck.shuffle()
	return deck


## The first round: biggest countries first. Tasks are dealt from the end of the deck, so
## the biggest band goes last. Shuffled within each band so no two games are the same.
func eased(deck: Array[int]) -> Array[int]:
	var biggest_first: Array[int] = deck.duplicate()
	biggest_first.sort_custom(func(a: int, b: int) -> bool: return size_of(a) > size_of(b))
	var eased_deck: Array[int] = []
	for band_start in range(0, biggest_first.size(), EASING_BAND_SIZE):
		var band: Array[int] = biggest_first.slice(band_start, band_start + EASING_BAND_SIZE)
		band.shuffle()
		eased_deck = band + eased_deck
	return eased_deck


## How many pixels across the country is on its widest screen: the bigger, the easier.
func size_of(task_index: int) -> float:
	return float(tasks[task_index].country()["widest_view_pixels"])


func _process(delta: float) -> void:
	var is_asking: bool = current_task != null and not is_between_tasks
	if is_asking:
		seconds_on_task += delta
	var arrow: HintArrow = mode.hint_arrow
	arrow.is_wanted = is_asking and not mode.is_changing_screen and is_hint_due()
	if is_asking:
		arrow.origin = mode.pointer.position
		arrow.target = hint_target_position()


## Wrong tries or a long wait, or being in the wrong continent, where the
## only useful thing to point at is the way back out.
func is_hint_due() -> bool:
	return wrong_tries >= HINT_AFTER_WRONG_TRIES or seconds_on_task >= HINT_AFTER_SECONDS or is_in_wrong_continent()


func is_in_wrong_continent() -> bool:
	return mode.screen_name != MapMode.WORLD and not current_task.continent_ids().has(mode.screen_name)


## Where the arrow points. On the world: the continent. Inside the right
## continent: the country. Inside the wrong one: the globe, the way back.
func hint_target_position() -> Vector2:
	if mode.screen_name == MapMode.WORLD:
		return nearest_continent_label(current_task.continent_ids())
	if is_in_wrong_continent():
		return GlobeButton.BUTTON_RECT.get_center()
	var view: Dictionary = current_task.country()["views"][mode.screen_name]
	return Vector2(view["label"][0], view["label"][1])


## A country on two continents points at whichever is nearer the pin.
func nearest_continent_label(continent_ids: Array) -> Vector2:
	var nearest: Vector2 = Vector2.ZERO
	var nearest_distance: float = INF
	for continent_id in continent_ids:
		var label: Array = MapData.continent(continent_id)["label"]
		var label_position: Vector2 = Vector2(label[0], label[1])
		if mode.pointer.position.distance_to(label_position) < nearest_distance:
			nearest = label_position
			nearest_distance = mode.pointer.position.distance_to(label_position)
	return nearest


func on_country_picked(country_id: String) -> void:
	if current_task == null or is_between_tasks:
		return
	if country_id == current_task.country_id:
		finish_task()
		return
	wrong_tries += 1
	var picked: Dictionary = MapData.country(country_id)
	if current_task.country()["neighbours"].has(country_id):
		say("That's %s - so close!" % picked["name"])
	else:
		say("That's %s!" % picked["name"])


func on_continent_entered(continent_id: String) -> void:
	if current_task == null or is_between_tasks:
		return
	if not current_task.continent_ids().has(continent_id):
		wrong_tries += 1
		say("%s isn't in %s!" % [current_task.country_name(), MapData.continent(continent_id)["name"]])


## A few words above the pin, kept well inside the screen.
func say(message: String) -> void:
	var spot: Vector2 = mode.pointer.position + Vector2(0, -190)
	if spot.y < 230.0:
		spot = mode.pointer.position + Vector2(0, 150)
	spot.x = clampf(spot.x, 620.0, 1300.0)
	FloatingText.show_at(mode.effects_layer, spot, message, PaintColours.INK, 52, MESSAGE_SECONDS, 50.0)


func finish_task() -> void:
	is_between_tasks = true
	var finished: MapTask = current_task
	GameSettings.record_found("countries_found", finished.country_id)
	mode.paint_country(finished.country_id)
	Sound.play("chime")
	mode.task_banner.celebrate()
	var rainbow_colour: Color = MapData.colour_of(int(finished.country()["colour"]))
	PaintSplash.burst(mode.effects_layer, mode.pointer.position, rainbow_colour, 16, 280)
	mode.effects_layer.add_child(Confetti.new())
	FloatingText.show_at(mode.effects_layer, mode.pointer.position + Vector2(0, -170), "%s!" % finished.country_name(), rainbow_colour.darkened(0.25), 72, 1.8)
	task_finished.emit(finished)
	await get_tree().create_timer(SECONDS_TO_CELEBRATE).timeout
	mode.task_banner.hide_task()
	if mode.screen_name != MapMode.WORLD:
		mode.zoom_to(MapMode.WORLD)
		await mode.zoom_finished
	start_task(deal_next_task_index(current_task_index))
