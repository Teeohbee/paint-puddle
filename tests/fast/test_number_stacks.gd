extends GameSuite
# Number stacks: drive into one and it follows; drive into another and they
# join. Exactly right finishes, too big comes apart, too small keeps going.

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

func stack_of(value):
	for thing in meadow.get_node("StonesAndDrops").get_children():
		if thing is NumberStack and thing.value == value and not thing.is_leaving and not thing.is_carried():
			return thing

func open_meadow_on(task_text):
	var tasks = load("res://core/meadow_task.gd").load_list("res://data/tasks.json")
	var task_index = -1
	for index in tasks.size():
		if tasks[index].text == task_text:
			task_index = index
	GameSettings.record_progress("next_task_index", task_index)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	meadow = get_tree().current_scene
	blob = meadow.blob
	await get_tree().create_timer(1.2).timeout

func test_number_stacks() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	var Task = load("res://core/meadow_task.gd")
	check(Task.from_dictionary({"type": "join", "target": 7, "stacks": [3, 4, 5], "text": "?"}) != null, "make 7 from 3, 4, 5 loads")
	check(Task.from_dictionary({"type": "join", "target": 7, "stacks": [1, 2, 9], "text": "?"}) == null, "no stacks that make the target: skipped")
	check(Task.from_dictionary({"type": "join", "target": 7, "stacks": [7, 3, 4], "text": "?"}) == null, "a stack that is already the target: skipped")
	check(Task.from_dictionary({"type": "join", "target": 21, "stacks": [10, 11], "text": "?"}) == null, "targets stop at 20")
	var Stack = load("res://meadow/number_stack.gd")
	check(Stack.square_centres(4, 28.0).size() == 4, "4 has four squares")
	check(Stack.square_colour(1, 0) == PaintColours.RED and Stack.square_colour(2, 0) == PaintColours.ORANGE, "1 is red, 2 is orange")
	check(Stack.square_colour(7, 0) != Stack.square_colour(7, 1), "7 is stripes")
	check(Stack.edge_colour(Color.WHITE) == PaintColours.RED, "10 is white with a red edge")

	# Make 7 from 3, 4, 5
	await open_meadow_on("Make 7.")
	var runner = meadow.task_runner
	check(runner.current_task.type == "join", "the task is joining stacks")
	var three = stack_of(3)
	var four = stack_of(4)
	var five = stack_of(5)
	check(three != null and four != null and five != null, "3, 4 and 5 are in the grass")
	await visit(five.position)
	check(five.is_carried(), "driving into 5 picks it up")
	blob.position = Vector2(960, 740)
	await get_tree().create_timer(0.5).timeout
	check(five.position.distance_to(blob.position) < 150, "it follows the blob")
	await visit(four.position)
	check(not runner.is_between_tasks, "5 and 4 make 9, too many")
	check(runner.carried_stack == null and not five.is_carried(), "the 5 is put down")
	check(four.value == 4 and five.value == 5 and not four.is_leaving and not five.is_leaving, "both are still there")
	await get_tree().create_timer(0.8).timeout
	await visit(three.position)
	check(three.is_carried(), "the 3 is picked up")
	await visit(four.position)
	check(runner.is_between_tasks, "3 and 4 make 7")
	check(four.value == 7, "the stack becomes a 7")

	# Make 7 with three stacks
	await open_meadow_on("Make 7 with three stacks!")
	runner = meadow.task_runner
	var one = stack_of(1)
	var two = stack_of(2)
	four = stack_of(4)
	await visit(one.position)
	await visit(two.position)
	check(not runner.is_between_tasks and two.value == 3 and two.is_carried(), "1 and 2 make a 3 that keeps following: %s %s %s %s" % [runner.current_task.text, runner.is_between_tasks, two.value, two.is_carried()])
	await visit(four.position)
	check(runner.is_between_tasks, "then 4 more makes 7")

