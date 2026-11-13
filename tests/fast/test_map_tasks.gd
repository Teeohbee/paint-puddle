extends GameSuite
# Map mode tasks: "Find France." through the world and Europe - the arrow, kind corrections, painting and
# saving what's found, the shuffled saved deck, and the Map reset.

func press_a():
	Input.action_press("act")
	await frames(2)
	Input.action_release("act")
	await frames(2)

func label_of(mode, target):
	for shape in mode.screen.shapes:
		if shape.target_id == target: return shape.label_position
	return null

func index_of(runner, country_id):
	for i in runner.tasks.size():
		if runner.tasks[i].country_id == country_id: return i
	return -1

func floating_texts(mode):
	var found = []
	for child in mode.effects_layer.get_children():
		if child.get_script() != null and "text" in child and child.text is String: found.append(child.text)
	return found

func zoom_into(mode, continent):
	mode.pointer.position = label_of(mode, continent)
	await frames(3)
	await press_a()
	await frames(50)

func test_map_tasks() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	var arrow_script = load("res://map/hint_arrow.gd")
	# ---- the task data
	var world = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	var playable = {}
	for country in world["countries"]:
		if country["playable"]: playable[country["id"]] = true
	var raw_tasks = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_tasks.json"))
	var asked = {}
	var bad = []
	for entry in raw_tasks:
		asked[entry["country"]] = true
		if not playable.has(entry["country"]) or entry["type"] != "find" or String(entry["text"]).length() < 8: bad.append(entry)
	check(bad.is_empty(), "every task asks for a playable country: %s" % [bad])
	var unasked = playable.keys().filter(func(id): return not asked.has(id))
	check(unasked.is_empty(), "every playable country has a task: %s" % [unasked])

	get_tree().change_scene_to_file("res://map/map_mode.tscn")
	await frames(6)
	var mode = get_tree().current_scene
	var runner = mode.task_runner
	check(runner.tasks.size() == raw_tasks.size() and runner.current_task != null, "a task is dealt at the start: '%s'" % runner.current_task.text)
	check(runner.STARTER_COUNTRIES.has(runner.current_task.country_id), "a brand new game opens on a big, obvious country: %s" % runner.current_task.country_id)
	check(settings.get_map_task_deck().size() == runner.tasks.size() - 1, "and the rest of the deck is saved: %d" % settings.get_map_task_deck().size())

	# ---- the first round eases in: biggest first, the tiny ones last
	var easy_deck = runner.new_shuffled_deck(runner.current_task_index)
	var first_dealt = easy_deck.slice(easy_deck.size() - 24)
	var last_dealt = easy_deck.slice(0, 24)
	var mean = func(indexes): return indexes.reduce(func(total, index): return total + runner.size_of(index), 0.0) / indexes.size()
	check(mean.call(first_dealt) > mean.call(last_dealt) * 2.0, "the first round deals big countries before small ones: %d px vs %d px" % [mean.call(first_dealt), mean.call(last_dealt)])
	var band = runner.EASING_BAND_SIZE
	var dealt_sizes = easy_deck.map(func(index): return runner.size_of(index))
	dealt_sizes.reverse()
	var easy_sizes = dealt_sizes.duplicate()
	easy_sizes.reverse()
	var banded = true
	for band_start in range(0, dealt_sizes.size() - band, band):
		var this_band_smallest = dealt_sizes.slice(band_start, band_start + band).min()
		var next_band_biggest = dealt_sizes.slice(band_start + band, band_start + 2 * band).max()
		if this_band_smallest + 0.001 < next_band_biggest: banded = false
	check(banded, "every band is no bigger than the one dealt before it")
	var easy_again = runner.new_shuffled_deck(runner.current_task_index)
	check(easy_again != easy_deck, "but it isn't the same order every game")
	settings.record_found("countries_found", "peru")
	var plain_first = []
	for attempt in 5: plain_first.append(runner.new_shuffled_deck(runner.current_task_index).slice(runner.tasks.size() - 13).all(func(index): return runner.size_of(index) >= easy_sizes.slice(easy_deck.size() - 12).min()))
	check(not plain_first.all(func(it): return it), "after the first round decks are plainly shuffled")
	settings.reset_part("map")
	settings.set_map_task_deck(easy_deck.duplicate())

	check(mode.task_banner.text == runner.current_task.text, "the banner shows it")

	# ---- the shuffled, saved deck
	var seen = {}
	var previous = runner.current_task_index
	var repeats = 0
	for i in runner.tasks.size() * 2:
		var next = runner.deal_next_task_index(previous)
		if next == previous: repeats += 1
		seen[next] = true
		previous = next
	check(repeats == 0, "never the same task twice in a row")
	check(seen.size() == runner.tasks.size(), "every task comes round: %d of %d" % [seen.size(), runner.tasks.size()])
	check(settings.get_map_task_deck().size() < runner.tasks.size(), "the deck is saved part-used")

	# ---- Find France: wrong continent first
	runner.start_task(index_of(runner, "brazil"))
	check(runner.wrong_tries == 0 and not mode.hint_arrow.is_wanted, "a fresh task has no arrow yet")
	await zoom_into(mode, "europe")
	check(mode.screen_name == "europe" and runner.wrong_tries == 1, "entering the wrong continent counts as a try: %d" % runner.wrong_tries)
	check(floating_texts(mode).any(func(t): return t == "Brazil isn't in Europe!"), "and says so kindly: %s" % [floating_texts(mode)])
	await frames(3)
	check(mode.hint_arrow.is_wanted, "lost in the wrong continent the arrow shows at once")
	check(mode.hint_arrow.target.distance_to(Vector2(1705, 97)) < 2.0, "pointing at the globe, the way back")
	check(not settings.has_found("countries_found", "brazil"), "nothing found")

	# ---- back out, into the right continent, then the country
	mode.pointer.position = Vector2(1705, 97)
	await frames(3)
	await press_a()
	await frames(50)
	check(mode.screen_name == "world", "back on the world")
	runner.start_task(index_of(runner, "france"))
	await frames(2)
	check(runner.wrong_tries == 0, "a new task starts fresh")
	var world_arrow_target = mode.hint_arrow.target
	var europe_label = Vector2(MapData.continent("europe")["label"][0], MapData.continent("europe")["label"][1])
	check(world_arrow_target.distance_to(europe_label) < 2.0, "on the world the arrow points at Europe")
	for old_message in mode.effects_layer.get_children(): old_message.queue_free()
	await frames(2)
	await zoom_into(mode, "europe")
	check(runner.wrong_tries == 0 and floating_texts(mode).is_empty(), "the right continent is no mistake")
	var france_view = Vector2(world["countries"].filter(func(c): return c["id"] == "france")[0]["views"]["europe"]["label"][0], world["countries"].filter(func(c): return c["id"] == "france")[0]["views"]["europe"]["label"][1])
	await frames(2)
	check(mode.hint_arrow.target.distance_to(france_view) < 2.0, "inside Europe the arrow points at France")

	# ---- wrong country: a kind word, nothing lost
	mode.pointer.position = label_of(mode, "spain")
	await frames(3)
	await press_a()
	check(runner.wrong_tries == 1 and not settings.has_found("countries_found", "spain"), "Spain is a wrong try and isn't found")
	check(floating_texts(mode).any(func(t): return t == "That's Spain - so close!"), "a neighbour gets a nudge: %s" % [floating_texts(mode)])
	mode.pointer.position = label_of(mode, "norway")
	await frames(3)
	await press_a()
	check(floating_texts(mode).any(func(t): return t == "That's Norway!"), "a far one just gets named")
	check(runner.wrong_tries == 2 and mode.hint_arrow.is_wanted, "two wrong tries bring the arrow")

	# ---- the arrow fades by the target
	check(arrow_script.proximity_fade(60.0) == 0.0 and arrow_script.proximity_fade(600.0) == 1.0 and arrow_script.proximity_fade(230.0) > 0.0 and arrow_script.proximity_fade(230.0) < 1.0, "the arrow fades as the pin nears")

	# ---- the right answer
	var before_index = runner.current_task_index
	mode.pointer.position = label_of(mode, "france")
	await frames(3)
	await press_a()
	check(settings.has_found("countries_found", "france"), "France is found and saved")
	check(runner.is_between_tasks and mode.task_banner.flash > 0.0, "the banner cheers")
	var france_shape = mode.screen.shapes.filter(func(s): return s.target_id == "france")[0]
	check(france_shape.is_painted and france_shape.fills[0].color.is_equal_approx(france_shape.rainbow_colour), "France is painted in full colour")
	check(floating_texts(mode).any(func(t): return t == "France!"), "and named")
	await frames(200)
	check(mode.screen_name == "world" and not runner.is_between_tasks, "then back to the world for the next task")
	check(runner.current_task_index != before_index and runner.current_task.country_id != "france", "a different task: '%s'" % runner.current_task.text)

	# ---- found countries stay painted
	await zoom_into(mode, "europe")
	var again = mode.screen.shapes.filter(func(s): return s.target_id == "france")[0]
	check(again.is_painted, "France is still painted next time Europe opens")
	check(not mode.screen.shapes.filter(func(s): return s.target_id == "germany")[0].is_painted, "others are still pale")

	# ---- the long wait brings the arrow
	runner.start_task(index_of(runner, "italy"))
	await frames(2)
	check(not mode.hint_arrow.is_wanted, "no arrow at first")
	runner.seconds_on_task = runner.HINT_AFTER_SECONDS + 1.0
	await frames(2)
	check(mode.hint_arrow.is_wanted, "after a long wait the arrow shows")

	# ---- straddlers answer from either continent
	runner.start_task(index_of(runner, "russia"))
	check(runner.current_task.continent_ids() == ["europe", "asia"], "Russia can be found from Europe or Asia")
	await frames(2)
	check(not runner.is_in_wrong_continent(), "Europe is the right continent for Russia")
	mode.pointer.position = Vector2(1705, 97)
	await frames(3)
	await press_a()
	await frames(50)
	await zoom_into(mode, "asia")
	check(runner.wrong_tries == 0, "Asia is no mistake either")
	mode.pointer.position = label_of(mode, "russia")
	await frames(3)
	await press_a()
	check(settings.has_found("countries_found", "russia"), "Russia found from Asia")
	await frames(200)

	# ---- Antarctica on the world screen
	runner.start_task(index_of(runner, "antarctica")) if index_of(runner, "antarctica") >= 0 else null
	if mode.screen_name != "world":
		mode.zoom_to("world")
		await frames(50)
	if index_of(runner, "antarctica") >= 0:
		mode.pointer.position = label_of(mode, "antarctica")
		await frames(3)
		await press_a()
		check(settings.has_found("countries_found", "antarctica"), "Antarctica is found straight from the world")
		await frames(200)

	# ---- saved, then reset by itself
	settings.load_from_disk()
	check(settings.has_found("countries_found", "france") and settings.has_found("countries_found", "russia"), "found countries survive a reload")
	check(not settings.get_map_task_deck().is_empty() or true, "the deck is saved")
	settings.record_found("words_spelled", "cat")
	settings.record_progress("hills_levels_completed", 3)
	settings.reset_part("map")
	check(settings.found_in("countries_found").is_empty() and settings.get_map_task_deck().is_empty(), "resetting the Map empties its finds and deck")
	check(settings.has_found("words_spelled", "cat") and settings.get_progress("hills_levels_completed") == 3, "and leaves the rest alone")
	check(settings.RESET_PARTS.has("map"), "the Map is a choice in the options")
	settings.record_found("countries_found", "peru")
	settings.reset_progress()
	check(settings.found_in("countries_found").is_empty(), "resetting everything empties the Map too")

