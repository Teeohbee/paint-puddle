@abstract
class_name GameSuite
extends GdUnitTestSuite
# Base for suites that touch the game's autoloads or screens. Every suite runs in one Godot process, so
# each test starts from what a fresh boot would give: default settings and progress saved somewhere
# scratch, one player, no screen and no scene change in flight, nothing paused, normal speed, no music.

# One file per process, so two runs side by side never share it
var scratch_path := "user://test_save_%d.json" % OS.get_process_id()
var real_path: String

func before_test() -> void:
	real_path = GameSettings.save_file_path
	GameSettings.save_file_path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.load_from_disk()
	reset_world()

func after_test() -> void:
	await settle()
	get_tree().unload_current_scene()
	reset_world()
	Music.stop()
	for player in Sound.players:
		player.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.save_file_path = real_path
	await get_tree().process_frame

func reset_world() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	PlayerSession.player_devices.clear()
	PlayerSession.missing_slots.clear()

func scene() -> Node:
	return get_tree().current_scene

# Straight to a screen, the way booting into it would, and waits for it to be ready
func open(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	return scene()

# Waits for any SceneManager change to finish
func settle() -> void:
	while SceneManager.is_changing_scene:
		await get_tree().process_frame

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
	await get_tree().process_frame
