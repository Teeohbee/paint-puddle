extends GameSuite
# Sea life layer: twelve boats, a creature every 20-40s taking turns whale/dolphins, never two at once,
# never near the avoid points, nothing new while held, and paused with the game.

var held = false
# Plays 5 minutes of sea, so it needs more than gdUnit's 5 minute default (game time, under --fixed-fps)
func test_sea_life(timeout := 400000) -> void:
	var sea_life_script = load("res://map/sea_life.gd")
	var creature_script = load("res://map/sea_creature.gd")
	var data = load("res://map/sea_life_data.gd")
	var pin = Vector2(250, 600)
	var sea = sea_life_script.new()
	sea.rng.seed = 7
	sea.avoid_points = func(): return [pin]
	get_tree().root.add_child(sea)
	await get_tree().process_frame
	check(sea.boats.size() == 12, "twelve boats: %d" % sea.boats.size())
	for boat in sea.boats:
		check(boat.speed >= 12.0 and boat.speed <= 18.0, "boat speed %.1f is 12-18px/s" % boat.speed)
		break
	check(sea.seconds_to_next >= 20.0 and sea.seconds_to_next <= 40.0, "first creature in 20-40s: %.1f" % sea.seconds_to_next)

	var most_at_once = 0
	var appearances = []
	var last_creature = null
	var frame_of_last = -1
	var gaps = []
	for frame in 60 * 300:
		await get_tree().process_frame
		var showing = sea.get_children().filter(func(child): return child is SeaCreature and not child.is_queued_for_deletion())
		most_at_once = max(most_at_once, showing.size())
		if sea.creature != null and sea.creature != last_creature:
			if frame_of_last >= 0: gaps.append((frame - frame_of_last) / 60.0)
			last_creature = sea.creature
			frame_of_last = frame
			appearances.append([sea.creature.kind, sea.creature.position])
	check(appearances.size() >= 5, "creatures came up %d times in 5 minutes" % appearances.size())
	check(most_at_once == 1, "never more than one at a time: %d" % most_at_once)
	var near_pin = appearances.filter(func(a): return a[1].distance_to(pin) < 250.0)
	check(near_pin.is_empty(), "none came up near the pin: %s" % [near_pin])
	var alternates = true
	for i in range(1, appearances.size()):
		if appearances[i][0] == appearances[i - 1][0]: alternates = false
	check(alternates and appearances[0][0] == creature_script.Kind.WHALE, "whale and dolphins take turns: %s" % [appearances.map(func(a): return a[0])])
	check(gaps.all(func(g): return g >= 20.0 + creature_script.SECONDS - 0.2 and g <= 40.0 + creature_script.SECONDS + 0.2), "gaps of 20-40s plus the show: %s" % [gaps])

	# held: nothing new comes up
	held = true
	sea.is_held = func(): return held
	while sea.creature != null: await get_tree().process_frame
	sea.seconds_to_next = 0.5
	for frame in 120: await get_tree().process_frame
	check(sea.creature == null and sea.seconds_to_next == 0.5, "nothing comes up while held")
	held = false
	for frame in 60: await get_tree().process_frame
	check(sea.creature != null, "comes up once no longer held: %s %.2f" % [sea.creature, sea.seconds_to_next])

	# every spot near something to avoid: wait and look again
	while sea.creature != null: await get_tree().process_frame
	sea.avoid_points = func(): return data.SPOTS
	sea.seconds_to_next = 0.1
	for frame in 30: await get_tree().process_frame
	check(sea.creature == null and sea.seconds_to_next > 1.0, "(%s %.2f) with every spot blocked, nothing comes up and it looks again later" % [sea.creature, sea.seconds_to_next])

	# get_tree().paused: boats and creatures stop
	sea.avoid_points = func(): return []
	sea.bring_up(creature_script.Kind.DOLPHINS, Vector2(820, 720))
	await get_tree().process_frame
	var boat = sea.boats[0]
	var boat_along = boat.along
	var creature_progress = sea.creature.progress
	get_tree().paused = true
	for frame in 60: await get_tree().process_frame
	check(boat.along == boat_along and sea.creature.progress == creature_progress, "get_tree().paused: boats and the creature stop")
	get_tree().paused = false
	for frame in 30: await get_tree().process_frame
	check(boat.along != boat_along and sea.creature.progress > creature_progress, "unpaused: they carry on")

	# both creatures draw at every stage without errors (errors show as SCRIPT ERROR)
	for kind in [creature_script.Kind.WHALE, creature_script.Kind.DOLPHINS]:
		var creature = creature_script.make(kind, Vector2(500, 500))
		get_tree().root.add_child(creature)
		for step in 21:
			creature.progress = step / 20.0
			await get_tree().process_frame
		creature.queue_free()
	# both creatures drew all the way through: a drawing error fails the test as a runtime error
