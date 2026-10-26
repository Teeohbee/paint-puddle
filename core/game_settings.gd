extends Node
## Settings and progress, saved to user://save.json. A missing or broken save
## never stops the game: it starts from the defaults and says so in the log.

signal setting_changed(setting_name: String, new_value: Variant)

const SAVE_FORMAT_VERSION: int = 1

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

var save_file_path: String = "user://save.json"
var settings: Dictionary = {}
var progress: Dictionary = {}


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
	save_to_disk()


func load_from_disk() -> void:
	settings = default_settings()
	progress = DEFAULT_PROGRESS.duplicate()
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


## Only names we know about are copied, and only whole numbers.
func copy_known_values(saved_values: Variant, into: Dictionary) -> void:
	if not saved_values is Dictionary:
		return
	for value_name in into:
		if saved_values.has(value_name) and (saved_values[value_name] is float or saved_values[value_name] is int):
			into[value_name] = int(saved_values[value_name])


func save_to_disk() -> void:
	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write save file %s: %s" % [save_file_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify({
		"version": SAVE_FORMAT_VERSION,
		"settings": settings,
		"progress": progress,
	}, "\t"))


func default_settings() -> Dictionary:
	var defaults: Dictionary = {}
	for setting_name in SETTING_LIMITS:
		defaults[setting_name] = SETTING_LIMITS[setting_name].default
	return defaults
