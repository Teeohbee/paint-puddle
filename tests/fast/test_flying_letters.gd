extends GameSuite
# Meadow Medium: every letter rides a butterfly, looping a figure of eight round where it was put down.
# Numbers and paint drops stay put, and Easy's letters stay still. A loop never crosses a bush, the rainbow,
# a puddle or the fountain, and stays inside the meadow: where a full loop won't fit, it shrinks.

var meadow
var runner

func open_meadow_on(difficulty: String, card: Dictionary) -> void:
	MeadowScript.difficulty = difficulty
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	meadow = get_tree().current_scene
	runner = meadow.task_runner
	runner.clear_the_grass()
	runner.current_task = MeadowTask.from_dictionary(card)
	runner.put_things_in_the_grass()
	await frames(2)

func stones() -> Array:
	return runner.things_in_the_grass.filter(func(thing): return thing is LetterStone and not thing.is_leaving)

func drops() -> Array:
	return runner.things_in_the_grass.filter(func(thing): return thing is PaintDrop)

func has_butterfly(stone) -> bool:
	return stone.get_children().any(func(child): return child is Butterfly)

func positions(things: Array) -> Array:
	return things.map(func(thing): return thing.position)

func keep_clear() -> Array[Dictionary]:
	return runner.places_to_keep_clear

func test_on_medium_every_letter_rides_a_butterfly_and_moves() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "spell", "word": "SANDWICH", "text": "Spell SANDWICH."})
	var before: Array = positions(stones())
	await frames(30)
	var after: Array = positions(stones())
	check(stones().size() == 8, "eight letters")
	for index in stones().size():
		check(has_butterfly(stones()[index]), "%s has a butterfly" % stones()[index].value)
		check(before[index].distance_to(after[index]) > 5.0, "%s flies" % stones()[index].value)

func test_on_medium_numbers_stay_put() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "sum", "question": "8 + 7", "answer": 15, "choices": [14, 15, 16], "text": "?"})
	var before: Array = positions(stones())
	await frames(30)
	check(positions(stones()) == before, "numbers don't move")
	check(not stones().any(has_butterfly), "and have no butterflies")

func test_on_medium_drops_stay_put() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "collect", "paint": "blue", "count": 9, "text": "?"})
	var before: Array = positions(drops())
	await frames(30)
	check(positions(drops()) == before, "drops don't move")

func test_on_easy_letters_stay_still() -> void:
	await open_meadow_on(TaskRunner.EASY, {"type": "spell", "word": "CAT", "text": "?"})
	var before: Array = positions(stones())
	await frames(30)
	check(positions(stones()) == before, "Easy's letters don't move")
	check(not stones().any(has_butterfly), "and have no butterflies")

func loop_points(home: Vector2, loop: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for step in 200:
		points.append(home + LetterFlight.loop_offset(TAU * step / 200.0, loop.size, loop.upright))
	return points

# Checked against the things themselves, not the keep-clear list: a stone's edge never touches them
func crossings(point: Vector2) -> Array[String]:
	var found: Array[String] = []
	var stone: float = LetterStone.RADIUS
	if point.distance_to(MeadowScript.RAINBOW_CENTRE) < RainbowBoard.OUTER_RADIUS + stone and point.y < MeadowScript.RAINBOW_CENTRE.y + stone:
		found.append("the rainbow")
	for pot in meadow.rainbow.pots:
		if point.distance_to(pot.global_position) < PaintPot.RADIUS + stone:
			found.append("the %s pot" % pot.paint_name)
	for puddle in meadow.puddles.values():
		if point.distance_to(puddle.position) < PaintPuddle.RADIUS + stone:
			found.append("the %s puddle" % puddle.paint_name)
	if point.distance_to(meadow.fountain.position) < Fountain.POOL_RADIUS + 14 + stone:
		found.append("the fountain")
	for bush in MeadowScript.BUSH_LAYOUT:
		if point.distance_to(bush.position) < bush.radius + stone:
			found.append("a bush")
	return found

func test_no_loop_crosses_anything_or_leaves_the_meadow() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "spell", "word": "CAT", "text": "?"})
	for spot in TaskRunner.FLYING_SPOTS + TaskRunner.FREE_SPOTS:
		var loop: Dictionary = LetterFlight.fitted_loop(spot, keep_clear())
		if loop.size == 0.0:
			continue  # stays still where Easy's stones sit
		for point in loop_points(spot, loop):
			check(LetterFlight.MEADOW_INSIDE.has_point(point), "the loop from %s stays inside the meadow" % spot)
			check(crossings(point).is_empty(), "the loop from %s crosses %s" % [spot, crossings(point)])

func test_every_flying_spot_has_room_to_fly() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "spell", "word": "CAT", "text": "?"})
	for spot in TaskRunner.FLYING_SPOTS:
		check(LetterFlight.fitted_loop(spot, keep_clear()).size >= LetterFlight.ROOMY_LOOP, "%s has room" % spot)
	check(TaskRunner.FLYING_SPOTS.size() >= 10, "enough for the longest Medium word, and two spare")

func test_a_loop_that_wont_fit_shrinks() -> void:
	var fountain := {"centre": Vector2(500, 500), "radius": 150.0}
	var open_grass: Dictionary = LetterFlight.fitted_loop(Vector2(900, 500), [fountain])
	check(open_grass.size == LetterFlight.LOOP_SIZE, "in open grass, a full loop: %s" % open_grass.size)
	var beside: Dictionary = LetterFlight.fitted_loop(Vector2(500, 660), [fountain])
	check(beside.size > 0.0 and beside.size < LetterFlight.LOOP_SIZE, "beside the fountain, a smaller one: %s" % beside.size)
	for point in loop_points(Vector2(500, 660), beside):
		check(point.distance_to(fountain.centre) >= fountain.radius - 1.0, "that doesn't cross it")

func test_letters_get_the_roomiest_spots() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "spell", "word": "SANDWICH", "text": "?"})
	for stone in stones():
		var flight: LetterFlight = stone.get_children().filter(func(child): return child is LetterFlight)[0]
		check(flight.loop_size >= LetterFlight.ROOMY_LOOP, "%s has room to fly: %s" % [stone.value, flight.loop_size])

func test_a_flying_letter_can_still_be_picked() -> void:
	await open_meadow_on(TaskRunner.MEDIUM, {"type": "spell", "word": "SUN", "text": "?"})
	await frames(20)
	var s_stone = stones().filter(func(stone): return stone.value == "S")[0]
	meadow.blob.position = s_stone.position
	await frames(3)
	check(runner.current_task.letters_done == 1, "driving into the flying S picks it")
	check(s_stone.is_leaving, "and it goes")
	var u_stone = stones().filter(func(stone): return stone.value == "U")[0]
	var u_was: Vector2 = u_stone.position
	await frames(10)
	check(u_stone.position != u_was, "the others carry on flying")
