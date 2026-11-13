extends GameSuite
# Taking away, stacks that make shapes, and numbers past ten.

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

func stacks_in_grass():
	var found = []
	for thing in meadow.get_node("StonesAndDrops").get_children():
		if thing is NumberStack and not thing.is_leaving and not thing.is_carried():
			found.append(thing)
	return found

func stack_of(value):
	for stack in stacks_in_grass():
		if stack.value == value:
			return stack

func stone_with(value):
	for thing in meadow.get_node("StonesAndDrops").get_children():
		if thing is LetterStone and thing.value == value and not thing.is_leaving:
			return thing

func open_meadow_on(task_text):
	var tasks = load("res://core/meadow_task.gd").load_list("res://data/tasks.json")
	var task_index = -1
	for index in tasks.size():
		if tasks[index].text == task_text:
			task_index = index
	check(task_index >= 0, "found the task: " + task_text)
	GameSettings.record_progress("next_task_index", task_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	await get_tree().create_timer(1.2).timeout

func test_split_and_shapes() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var Task = load("res://core/meadow_task.gd")
	var Stack = load("res://meadow/number_stack.gd")

	# Data rules
	check(Task.from_dictionary({"type": "split", "start": 8, "take": 3, "text": "?"}).split_choices() == [4, 5, 6], "8 take 3: stones 4, 5, 6")
	check(Task.from_dictionary({"type": "split", "start": 5, "take": 5, "text": "?"}) == null, "taking everything away is skipped")
	check(Task.from_dictionary({"type": "join", "target": 6, "stacks": [2, 4], "shape": "square", "text": "?"}) == null, "6 can't be a square")
	check(Task.from_dictionary({"type": "join", "target": 7, "stacks": [3, 4], "shape": "rows", "rows": 2, "text": "?"}) == null, "7 can't be 2 equal rows")

	# Layouts
	var square = Stack.square_centres(9, 28.0, "square")
	var xs = {}
	for centre in square:
		xs[centre.x] = true
	check(xs.size() == 3, "9 as a square is three across")
	var rows = Stack.square_centres(12, 28.0, "rows:3")
	var ys = {}
	for centre in rows:
		ys[centre.y] = true
	check(ys.size() == 3, "12 in 3 rows is three rows")
	var thirteen = Stack.square_centres(13, 28.0)
	check(thirteen[0].x < 0 and thirteen[10].x > 0, "13 is a ten with three beside it")
	check(Stack.square_colour(13, 0) == Color.WHITE and Stack.square_colour(13, 10) == PaintColours.YELLOW, "the ten is white, the three is yellow")

	# Take 3 away from 8
	await open_meadow_on("Take 3 away from 8. How many are left?")
	var runner = meadow.task_runner
	var eight = stack_of(8)
	check(eight != null and stacks_in_grass().size() == 1, "one 8 in the grass")
	check(stone_with("5") == null, "no stones yet")
	await visit(eight.position)
	await get_tree().create_timer(0.3).timeout
	check(eight.value == 5 and not eight.shows_number, "driving into the 8 leaves 5, number hidden")
	await get_tree().create_timer(1.0).timeout
	check(stone_with("4") != null and stone_with("5") != null and stone_with("6") != null, "stones ask 4, 5 or 6")
	await visit(stone_with("6").position)
	check(not runner.is_between_tasks, "6 is wrong")
	await visit(stone_with("5").position)
	check(runner.is_between_tasks and eight.shows_number, "5 is right, and the 5 shows its number")

	# Make 9. Is it a square too?
	await open_meadow_on("Make 9. Is it a square too?")
	runner = meadow.task_runner
	var four = stack_of(4)
	var five = stack_of(5)
	await visit(four.position)
	await visit(five.position)
	check(runner.is_between_tasks and five.value == 9 and five.arrangement == "square", "4 and 5 make a square 9")

	# Make 3 rows of 4
	await open_meadow_on("Make 3 rows of 4!")
	runner = meadow.task_runner
	var fours = stacks_in_grass().filter(func(stack): return stack.value == 4)
	check(fours.size() == 3, "three 4s")
	await visit(fours[0].position)
	await visit(fours[1].position)
	await visit(fours[2].position)
	var twelve = stacks_in_grass().filter(func(stack): return stack.value == 12)
	check(runner.is_between_tasks and fours[2].value == 12 and fours[2].arrangement == "rows:3", "three 4s make 3 rows of 4")

