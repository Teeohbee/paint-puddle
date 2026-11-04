extends Node
## Settings, progress and collections, saved to user://save.json. A missing
## or broken save never stops the game: it starts from the defaults and says
## so in the log.

signal setting_changed(setting_name: String, new_value: Variant)

## Version 2 added collections, and the second round of Meadow tasks.
const SAVE_FORMAT_VERSION: int = 2
## The first round of Meadow tasks. A version 1 save that has done them all
## moves on to the first task of the second round instead of going round again.
const TASKS_IN_THE_FIRST_ROUND: int = 44

## Each setting: its default, smallest and largest value.
const SETTING_LIMITS: Dictionary = {
	"music_volume": {"default": 7, "smallest": 0, "largest": 10},
	"sound_volume": {"default": 8, "smallest": 0, "largest": 10},
	"game_speed_percent": {"default": 100, "smallest": 50, "largest": 100},
	"gap_size_percent": {"default": 100, "smallest": 50, "largest": 100},
	"coyote_time_milliseconds": {"default": 250, "smallest": 100, "largest": 500},
}

const DEFAULT_PROGRESS: Dictionary = {
	"hills_levels_completed": 0,
	"rainbows_painted": 0,
	"tasks_completed": 0,
	"next_task_index": 0,
}

## Lists of things found, by name, in the order they were found.
const COLLECTION_NAMES: Array[String] = ["words_spelled", "colours_found"]

var save_file_path: String = "user://save.json"
var settings: Dictionary = {}
var progress: Dictionary = {}
var collections: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func get_setting(setting_name: String) -> int:
	return settings[setting_name]


func set_setting(setting_name: String, new_value: int) -> void:
	var limits: Dictionary = SETTING_LIMITS[setting_name]
	settings[setting_name] = clampi(new_value, limits.smallest, limits.largest)
	save_to_disk()
	setting_changed.emit(setting_name, settings[setting_name])


func game_speed() -> float:
	return get_setting("game_speed_percent") / 100.0


func get_progress(progress_name: String) -> int:
	return progress[progress_name]


func record_progress(progress_name: String, new_value: int) -> void:
	progress[progress_name] = new_value
	save_to_disk()


func reset_progress() -> void:
	progress = DEFAULT_PROGRESS.duplicate()
	collections = empty_collections()
	save_to_disk()


func has_found(collection_name: String, thing_name: String) -> bool:
	return collections[collection_name].has(thing_name)


## Adds it to the collection and saves. Returns true if it's newly found.
func record_found(collection_name: String, thing_name: String) -> bool:
	if has_found(collection_name, thing_name):
		return false
	collections[collection_name].append(thing_name)
	save_to_disk()
	return true


## A copy, so changing it doesn't change the save.
func found_in(collection_name: String) -> Array[String]:
	return collections[collection_name].duplicate()


func empty_collections() -> Dictionary:
	var empty: Dictionary = {}
	for collection_name in COLLECTION_NAMES:
		var things: Array[String] = []
		empty[collection_name] = things
	return empty


func load_from_disk() -> void:
	settings = default_settings()
	progress = DEFAULT_PROGRESS.duplicate()
	collections = empty_collections()
	if not FileAccess.file_exists(save_file_path):
		return
	var saved_text: String = FileAccess.get_file_as_string(save_file_path)
	var parser: JSON = JSON.new()
	var parsed_cleanly: bool = parser.parse(saved_text) == OK
	var saved: Variant = parser.data
	if not parsed_cleanly or not saved is Dictionary:
		push_warning("Save file %s couldn't be read, starting from defaults" % save_file_path)
		return
	copy_known_values(saved.get("settings", {}), settings)
	copy_known_values(saved.get("progress", {}), progress)
	for setting_name in SETTING_LIMITS:
		var limits: Dictionary = SETTING_LIMITS[setting_name]
		settings[setting_name] = clampi(settings[setting_name], limits.smallest, limits.largest)
	# Progress only ever counts up from 0; a negative count would lock level 1
	for progress_name in progress:
		progress[progress_name] = maxi(progress[progress_name], 0)
	copy_known_collections(saved.get("collections", {}))
	var saved_version: Variant = saved.get("version", 1)
	var is_from_before_collections: bool = not (saved_version is float or saved_version is int) or saved_version < 2
	if is_from_before_collections and progress.tasks_completed >= TASKS_IN_THE_FIRST_ROUND:
		progress.next_task_index = TASKS_IN_THE_FIRST_ROUND


## Only names we know about are copied, and only whole numbers.
func copy_known_values(saved_values: Variant, into: Dictionary) -> void:
	if not saved_values is Dictionary:
		return
	for value_name in into:
		if saved_values.has(value_name) and (saved_values[value_name] is float or saved_values[value_name] is int):
			into[value_name] = int(saved_values[value_name])


## Only collections we know about, only names (strings), each name once.
func copy_known_collections(saved_collections: Variant) -> void:
	if not saved_collections is Dictionary:
		return
	for collection_name in COLLECTION_NAMES:
		var saved_things: Variant = saved_collections.get(collection_name, [])
		if not saved_things is Array:
			continue
		for thing_name in saved_things:
			if thing_name is String and not collections[collection_name].has(thing_name):
				collections[collection_name].append(thing_name)


func save_to_disk() -> void:
	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write save file %s: %s" % [save_file_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify({
		"version": SAVE_FORMAT_VERSION,
		"settings": settings,
		"progress": progress,
		"collections": collections,
	}, "\t"))


func default_settings() -> Dictionary:
	var defaults: Dictionary = {}
	for setting_name in SETTING_LIMITS:
		defaults[setting_name] = SETTING_LIMITS[setting_name].default
	return defaults
