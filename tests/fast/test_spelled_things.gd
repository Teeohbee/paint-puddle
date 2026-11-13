extends GameSuite
# Spell a word that has a picture and the thing comes to life in the meadow.
# No more than six at once (the oldest leaves), and none left from last visit.

var meadow
var blob

func visit(target_position):
	blob.position = Vector2(960, 740)
	await get_tree().physics_frame
	await get_tree().physics_frame
	blob.position = target_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

func stone_with(value):
	for stone in meadow.get_node("StonesAndDrops").get_children():
		if stone is LetterStone and stone.value == value and not stone.is_leaving:
			return stone

func open_meadow_on_task(task_index):
	GameSettings.record_progress("next_task_index", task_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	await get_tree().create_timer(1.2).timeout

func things_staying():
	return meadow.spelled_things.things_staying()

func test_spelled_things() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	# Task data
	var MeadowTaskClass = load("res://core/meadow_task.gd")
	check(MeadowTaskClass.from_dictionary({"type": "spell", "word": "DOG", "thing": "dog", "text": "Spell DOG."}) != null, "a spell task with a thing loads")
	check(MeadowTaskClass.from_dictionary({"type": "spell", "word": "YAK", "thing": "yak", "text": "?"}) == null, "a thing with no picture is skipped")
	check(MeadowTaskClass.from_dictionary({"type": "spell", "word": "CAT", "thing": "dog", "text": "?"}) == null, "the thing must be the word")

	# Spelling CAT brings a cat to life
	await open_meadow_on_task(41)
	check(meadow.task_runner.current_task.thing == "cat", "task 41 is the first new task, spelling CAT")
	check(things_staying().is_empty(), "the meadow starts with nothing spelled")
	for letter in "CAT":
		var stone_position = stone_with(letter).position
		await visit(stone_position)
	await get_tree().process_frame
	check(things_staying().size() == 1 and things_staying()[0].thing_name == "cat", "a cat came to life")
	check(settings.has_found("words_spelled", "cat"), "the cat is in the book")
	check(not things_staying()[0] is CollisionObject2D, "it's nothing to bump into")

	# It wanders, only to good spots
	var cat = things_staying()[0]
	var spots_ok = true
	for attempt in 40:
		var spot = cat.pick_next_spot()
		if spot != cat.position and not meadow.spelled_things.is_good_spot(spot):
			spots_ok = false
	check(spots_ok, "it only wanders to clear grass")
	check(not meadow.spelled_things.is_good_spot(meadow.puddles["red"].position), "a puddle isn't clear grass")
	check(not meadow.spelled_things.is_good_spot(meadow.RAINBOW_CENTRE), "nor is the rainbow")
	var meadow_things = meadow.spelled_things
	var paths_ok = true
	for attempt in 1000:
		cat.position = meadow_things.good_spot_away_from(Vector2(-1000, -1000))
		var spot = cat.pick_next_spot()
		for step in 401:
			var on_the_way = cat.position.lerp(spot, step / 400.0)
			for place in meadow_things.places_to_keep_clear:
				if on_the_way.distance_to(place.centre) < place.radius:
					paths_ok = false
	check(paths_ok, "it never walks through the rainbow, a puddle, the fountain or a bush")
	var fountain_side = meadow.FOUNTAIN_POSITION + Vector2(-250, 0)
	check(not meadow_things.is_clear_path(fountain_side, meadow.FOUNTAIN_POSITION + Vector2(250, 0)), "straight across the fountain isn't a clear path")
	check(meadow_things.is_clear_path(meadow.FOUNTAIN_POSITION + Vector2(0, 100), meadow.FOUNTAIN_POSITION + Vector2(0, 400)), "walking out of a place you're already in is fine")

	# Drawn by depth with the blob and bushes
	var grass = meadow.get_node("ThingsOnTheGrass")
	check(meadow_things.get_parent() == grass and grass.y_sort_enabled and meadow_things.y_sort_enabled, "things are depth-sorted with the blob and bushes")
	check(meadow.get_node("StonesAndDrops").get_index() < grass.get_index(), "stones are still drawn under the grass layer")

	# Never stands on a stone
	var stone_spot = Vector2(1500, 850)
	var stone = load("res://meadow/letter_stone.gd").new()
	stone.position = stone_spot
	meadow.get_node("StonesAndDrops").add_child(stone)
	check(not meadow_things.is_good_spot(stone_spot + Vector2(60, 0)), "next to a stone isn't clear grass")
	check(not meadow_things.is_clear_path(stone_spot + Vector2(-300, 0), stone_spot + Vector2(300, 0)), "nor is walking over one")
	cat.position = stone_spot + Vector2(30, 0)
	cat.seconds_resting = 10.0
	var walked_off = false
	for wait in 60:
		await get_tree().create_timer(0.1).timeout
		if cat.position.distance_to(stone_spot) >= meadow_things.CLEAR_DISTANCE_FROM_STONES:
			walked_off = true
			break
	check(walked_off, "a thing a stone appears under hops clear of it: %s" % cat.position.distance_to(stone_spot))
	stone.queue_free()

	var start = cat.position
	await get_tree().create_timer(5.0).timeout
	check(cat.position != start, "it hops about: %s -> %s" % [start, cat.position])

	# Six at most
	for thing_name in ["dog", "pig", "hen", "cow", "fox"]:
		meadow.spelled_things.bring_to_life(thing_name, Vector2(300, 800))
	check(things_staying().size() == 6, "six fit")
	meadow.spelled_things.bring_to_life("owl", Vector2(300, 800))
	var names = things_staying().map(func(thing): return thing.thing_name)
	check(names.size() == 6 and not names.has("cat") and names.has("owl"), "a seventh sends the oldest, the cat, away: %s" % [names])
	check(is_instance_valid(cat) and cat.is_leaving, "the cat is leaving")
	await get_tree().create_timer(9.0).timeout
	check(not is_instance_valid(cat), "and has gone off the edge")

	# Next visit starts empty
	await open_meadow_on_task(42)
	check(things_staying().is_empty(), "coming back, the meadow is empty again")
	check(settings.has_found("words_spelled", "cat"), "but the book still has the cat")

