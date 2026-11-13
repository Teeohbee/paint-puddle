@abstract
class_name GameSuite
extends GdUnitTestSuite
# Base for suites that touch the game's autoloads or screens. Every suite runs in one Godot process, so
# each test starts from what a fresh boot would give: default settings and progress saved somewhere
# scratch, one player, no screen and no scene change in flight, nothing paused, normal speed, no music.
# Anything a test hangs on the root is freed after it.

# One file per process, so two runs side by side never share it
var scratch_path := "user://test_save_%d.json" % OS.get_process_id()
var real_path: String
var root_children_before: Array[Node] = []

# Static vars outlive a scene, so a fresh boot is the only other thing that resets them
const MenuScreenScript = preload("res://ui/menu_screen.gd")
const HillsLevelScript = preload("res://hills/hills_level.gd")
const PaintStudioScript = preload("res://paint/paint_studio.gd")

func before_test() -> void:
	real_path = GameSettings.save_file_path
	GameSettings.save_file_path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.load_from_disk()
	reset_world()
	root_children_before = get_tree().root.get_children()

func after_test() -> void:
	while SceneManager.is_changing_scene:
		await get_tree().process_frame
	get_tree().unload_current_scene()
	for child in get_tree().root.get_children():
		if not root_children_before.has(child) and child != get_tree().current_scene:
			child.queue_free()
	reset_world()
	Music.stop()
	for player in Sound.players:
		player.stop()
	Input.flush_buffered_events()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.save_file_path = real_path
	await get_tree().process_frame

func reset_world() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	PlayerSession.player_devices.clear()
	PlayerSession.missing_slots.clear()
	SceneManager.coverage = 0.0
	MenuScreenScript.last_choices = {}
	HillsLevelScript.level_to_play = 0
	HillsLevelScript.difficulty = HillsLevels.EASY
	HillsLevelScript.level_just_finished = -1
	PaintStudioScript.colour_set = "paint"

# An assertion that reads like the game: the message says what should be true
func check(condition: bool, message: String) -> void:
	assert_bool(condition).override_failure_message(message).is_true()

# count physics frames, then the frame that draws them
func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
	await get_tree().process_frame
