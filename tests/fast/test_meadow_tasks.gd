extends GdUnitTestSuite
# Meadow tasks: how each kind answers what the player does, which bad tasks are skipped, and the shape of
# the starter pack in data/tasks.json.

func test_spelling_takes_the_letters_in_order() -> void:
	var spell := MeadowTask.from_dictionary({"type": "spell", "word": "RED", "text": "Spell RED."})
	assert_str(spell.handle({"kind": "stone", "value": "E"})).is_equal("wrong")
	assert_str(spell.handle({"kind": "stone", "value": "R"})).is_equal("progress")
	assert_int(spell.letters_done).is_equal(1)
	assert_str(spell.handle({"kind": "stone", "value": "E"})).is_equal("progress")
	assert_str(spell.handle({"kind": "paint_changed", "paint": "red"})).is_equal("ignored")
	assert_str(spell.handle({"kind": "stone", "value": "D"})).is_equal("done")

func test_collecting_counts_only_the_right_paint() -> void:
	var collect := MeadowTask.from_dictionary({"type": "collect", "paint": "blue", "count": 2, "text": "Collect 2 blue drops."})
	assert_str(collect.handle({"kind": "drop", "paint": "red"})).is_equal("wrong")
	assert_str(collect.handle({"kind": "drop", "paint": "blue"})).is_equal("progress")
	assert_int(collect.collected).is_equal(1)
	assert_str(collect.handle({"kind": "drop", "paint": "blue"})).is_equal("done")

func test_a_sum_has_one_stone_per_choice_and_one_right_answer() -> void:
	var sum := MeadowTask.from_dictionary({"type": "sum", "question": "2 + 1", "answer": 3, "choices": [2, 3, 4], "text": "What is 2 + 1?"})
	assert_array(sum.stone_values()).is_equal(["2", "3", "4"])
	assert_str(sum.handle({"kind": "stone", "value": "4"})).is_equal("wrong")
	assert_str(sum.handle({"kind": "stone", "value": "3"})).is_equal("done")

func test_making_a_colour_waits_for_that_colour() -> void:
	var make := MeadowTask.from_dictionary({"type": "make", "paint": "green", "text": "Make green."})
	assert_str(make.handle({"kind": "paint_changed", "paint": "yellow"})).is_equal("ignored")
	assert_str(make.handle({"kind": "paint_changed", "paint": "green"})).is_equal("done")

func test_visiting_waits_for_the_right_place() -> void:
	var visit := MeadowTask.from_dictionary({"type": "visit", "target": "fountain", "text": "Wash in the fountain."})
	assert_str(visit.handle({"kind": "visited", "target": "puddle:red"})).is_equal("ignored")
	assert_str(visit.handle({"kind": "visited", "target": "fountain"})).is_equal("done")

func test_the_rainbow_is_done_when_finished_not_per_stripe() -> void:
	var rainbow := MeadowTask.from_dictionary({"type": "rainbow", "text": "Paint the whole rainbow!"})
	assert_str(rainbow.handle({"kind": "pot_filled", "paint": "red"})).is_equal("ignored")
	assert_str(rainbow.handle({"kind": "rainbow_finished"})).is_equal("done")

func test_bad_tasks_are_skipped(task: Dictionary, test_parameters := [
	[{"type": "spell", "text": "no word"}],
	[{"type": "dance", "text": "?"}],
	[{"type": "collect", "paint": "pink", "count": 2, "text": "?"}],
	[{"type": "sum", "question": "1 + 1", "answer": 2, "choices": [1, 3], "text": "?"}],
]) -> void:
	assert_object(MeadowTask.from_dictionary(task)).is_null()

# The meadow has room for 13 things, 2 of them wrong-colour drops, so a task can ask for 1 to 11 drops
func test_a_collect_task_asks_for_as_many_drops_as_the_meadow_has_room_for(count: int, is_kept: bool, test_parameters := [
	[0, false],
	[1, true],
	[11, true],
	[12, false],
]) -> void:
	var task := MeadowTask.from_dictionary({"type": "collect", "paint": "blue", "count": count, "text": "?"})
	assert_bool(task != null).override_failure_message("collecting %d drops should be %s" % [count, "kept" if is_kept else "skipped"]).is_equal(is_kept)

func test_the_starter_pack_loads_every_task_and_kind() -> void:
	var tasks := MeadowTask.load_list("res://data/tasks.json")
	var raw_count: int = JSON.parse_string(FileAccess.get_file_as_string("res://data/tasks.json")).size()
	assert_int(tasks.size()).override_failure_message("a task in the pack is skipped").is_equal(raw_count)
	var types := {}
	for task in tasks:
		types[task.type] = true
	assert_int(types.size()).is_equal(9)

func test_the_second_round_starts_with_cat_after_the_first_rainbow() -> void:
	# Old saves are moved to index 41, so this order is load-bearing
	var tasks := MeadowTask.load_list("res://data/tasks.json")
	assert_int(tasks.size()).is_greater(41)
	assert_str(tasks[40].type).is_equal("rainbow")
	assert_str(tasks[41].word).is_equal("CAT")

func test_every_picture_and_puddle_in_the_pack_exists() -> void:
	var bad := []
	for task in MeadowTask.load_list("res://data/tasks.json"):
		if task.thing != "" and not ThingDrawings.can_draw(task.thing):
			bad.append("no picture of a %s" % task.thing)
		if task.type == "visit" and task.target.begins_with("puddle:") \
				and not ["red", "yellow", "blue"].has(task.target.trim_prefix("puddle:")):
			bad.append("no %s in the meadow" % task.target)
	assert_array(bad).is_empty()
