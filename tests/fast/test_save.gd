extends GdUnitTestSuite
# The save file: settings and progress survive a restart, bad files fall back safely, the lists of things
# found (words spelled, colours mixed) are kept tidy, and old saves move on to the right task. Each test
# uses its own GameSettings, not the autoload, so "a restart" is just loading a second copy.

const GameSettingsScript = preload("res://core/game_settings.gd")

var path := "user://test_save_file_%d.json" % OS.get_process_id()

func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_no_save_file_means_defaults() -> void:
	var settings := _fresh_settings()
	assert_int(settings.get_setting("game_speed_percent")).is_equal(100)
	assert_float(settings.game_speed()).is_equal(1.0)
	assert_array(settings.found_in("words_spelled")).is_empty()

func test_settings_and_progress_survive_a_restart() -> void:
	var settings := _fresh_settings()
	settings.set_setting("game_speed_percent", 60)
	settings.set_setting("music_volume", 3)
	settings.record_progress("hills_levels_completed", 2)
	var reloaded := _fresh_settings()
	assert_int(reloaded.get_setting("game_speed_percent")).is_equal(60)
	assert_int(reloaded.get_setting("music_volume")).is_equal(3)
	assert_int(reloaded.get_progress("hills_levels_completed")).is_equal(2)

func test_game_speed_cant_go_below_half() -> void:
	var settings := _fresh_settings()
	settings.set_setting("game_speed_percent", 10)
	assert_int(settings.get_setting("game_speed_percent")).is_equal(50)

func test_a_corrupt_save_falls_back_to_defaults() -> void:
	_write_raw("{ this is not json")
	assert_int(_fresh_settings().get_setting("game_speed_percent")).is_equal(100)

func test_out_of_range_values_are_clamped_and_missing_ones_get_defaults() -> void:
	_write({"version": 1, "settings": {"music_volume": 99, "made_up": 1}})
	var settings := _fresh_settings()
	assert_int(settings.get_setting("music_volume")).is_equal(10)
	assert_int(settings.get_setting("sound_volume")).is_equal(8)

func test_reset_clears_progress_and_collections_but_keeps_settings() -> void:
	var settings := _fresh_settings()
	settings.set_setting("music_volume", 3)
	settings.record_progress("hills_levels_completed", 3)
	settings.record_found("words_spelled", "dog")
	settings.reset_progress()
	assert_int(settings.get_progress("hills_levels_completed")).is_equal(0)
	assert_array(settings.found_in("words_spelled")).is_empty()
	assert_int(settings.get_setting("music_volume")).is_equal(3)
	assert_array(_fresh_settings().found_in("words_spelled")).override_failure_message("the clear should be saved").is_empty()

func test_finding_something_is_new_only_once() -> void:
	var settings := _fresh_settings()
	assert_bool(settings.record_found("words_spelled", "dog")).is_true()
	assert_bool(settings.record_found("words_spelled", "dog")).is_false()
	assert_bool(settings.has_found("words_spelled", "dog")).is_true()
	assert_bool(settings.has_found("colours_found", "dog")).override_failure_message("collections are kept apart").is_false()

func test_found_things_survive_a_restart_in_order() -> void:
	var settings := _fresh_settings()
	settings.record_found("words_spelled", "dog")
	settings.record_found("words_spelled", "cat")
	settings.record_found("colours_found", "plum")
	var reloaded := _fresh_settings()
	assert_array(reloaded.found_in("words_spelled")).is_equal(["dog", "cat"])
	assert_array(reloaded.found_in("colours_found")).is_equal(["plum"])

func test_found_in_hands_out_a_copy() -> void:
	var settings := _fresh_settings()
	settings.record_found("words_spelled", "dog")
	settings.found_in("words_spelled").append("pig")
	assert_bool(settings.has_found("words_spelled", "pig")).is_false()

func test_junk_in_the_collections_is_tidied() -> void:
	_write({"version": 2, "collections": {"words_spelled": ["dog", 7, "dog", null, "cat"], "made_up": ["x"], "colours_found": "plum"}})
	var settings := _fresh_settings()
	assert_array(settings.found_in("words_spelled")).override_failure_message("only strings, no repeats").is_equal(["dog", "cat"])
	assert_array(settings.found_in("colours_found")).override_failure_message("a collection that isn't a list is empty").is_empty()
	_write({"version": 2, "collections": "nonsense"})
	assert_array(_fresh_settings().found_in("words_spelled")).is_empty()

func test_a_v1_save_that_finished_the_first_round_starts_on_cat() -> void:
	_write({"version": 1, "progress": {"tasks_completed": 50, "next_task_index": 6}})
	var settings := _fresh_settings()
	assert_int(settings.get_progress("next_task_index")).is_equal(41)
	assert_array(settings.found_in("words_spelled")).is_empty()
	settings.record_progress("next_task_index", 45)
	assert_int(_fresh_settings().get_progress("next_task_index")) \
		.override_failure_message("once saved as v2 it isn't moved again").is_equal(45)

func test_a_v1_save_part_way_through_the_first_round_stays_put() -> void:
	_write({"version": 1, "progress": {"tasks_completed": 10, "next_task_index": 10}})
	assert_int(_fresh_settings().get_progress("next_task_index")).is_equal(10)

func _fresh_settings() -> Node:
	var settings: Node = auto_free(GameSettingsScript.new())
	settings.save_file_path = path
	settings.load_from_disk()
	return settings

func _write(contents: Dictionary) -> void:
	_write_raw(JSON.stringify(contents))

func _write_raw(text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
