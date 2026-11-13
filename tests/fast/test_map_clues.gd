extends GameSuite
# Map picture clues: tasks can carry a drawing, a drawing we can't make is skipped, and every drawing in
# the data exists.

const MapTask = preload("res://map/map_task.gd")
const Drawings = preload("res://meadow/things/thing_drawings.gd")

func test_the_map_has_picture_clues_that_can_be_drawn() -> void:
	var clues := _clues()
	assert_int(clues.size()).is_greater_equal(6)
	var undrawable := clues.filter(func(t): return not Drawings.can_draw(t.thing)).map(func(t): return t.thing)
	assert_array(undrawable).is_empty()

func test_no_clue_says_its_own_country() -> void:
	var giveaways := _clues().filter(func(t): return t.text.to_lower().contains(t.country_name().to_lower()))
	assert_array(giveaways.map(func(t): return t.text)).is_empty()

func test_the_kangaroo_is_australias() -> void:
	var kangaroos := _clues().filter(func(t): return t.thing == "kangaroo")
	assert_array(kangaroos.map(func(t): return t.country_id)).is_equal(["australia"])

func test_a_clue_whose_picture_cant_be_drawn_is_skipped() -> void:
	var path := "user://map_clues_bad_%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('[{"type":"find","country":"france","text":"?","thing":"unicorn"},'
		+ '{"type":"find","country":"france","text":"ok","thing":"tower"}]')
	file.close()
	var loaded: Array = MapTask.load_list(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_array(loaded.map(func(t): return t.thing)).is_equal(["tower"])

func _clues() -> Array:
	return MapTask.load_list().filter(func(t): return t.thing != "")
