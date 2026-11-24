extends GameSuite
# A stone is picked when the blob drives onto it. If the next letter is already under the blob when it becomes
# the one wanted (it was turned away a moment ago, or a flying letter looped into the blob), it's picked then,
# without having to drive off and back on. Found when a flying L stayed under a blob following it for 40 s.

const SPOT: Vector2 = Vector2(960, 700)

var meadow
var runner

func open_meadow_spelling(word: String) -> void:
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	meadow = get_tree().current_scene
	runner = meadow.task_runner
	runner.clear_the_grass()
	runner.current_task = MeadowTask.from_dictionary({"type": "spell", "word": word, "text": "?"})
	runner.put_things_in_the_grass()
	await frames(2)

func stone(value: String):
	return runner.things_in_the_grass.filter(func(thing): return thing is LetterStone and thing.value == value)[0]

func test_the_next_letter_already_under_the_blob_is_picked() -> void:
	await open_meadow_spelling("SUN")
	meadow.blob.position = SPOT
	stone("U").position = SPOT
	await frames(3)
	check(runner.current_task.letters_done == 0, "U first is turned away")
	stone("S").position = SPOT
	await frames(3)
	check(runner.current_task.letters_done == 2, "S, then the U still under the blob: %d" % runner.current_task.letters_done)

func test_a_wrong_letter_under_the_blob_is_left_alone() -> void:
	await open_meadow_spelling("SUN")
	meadow.blob.position = SPOT
	var n = stone("N")
	n.position = SPOT
	await frames(3)
	stone("S").position = SPOT
	await frames(3)
	check(runner.current_task.letters_done == 1, "only S: %d" % runner.current_task.letters_done)
	check(not n.is_leaving, "N waits its turn")
