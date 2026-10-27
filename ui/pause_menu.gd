class_name PauseMenu
extends CanvasLayer
## Menu (Start) pauses the game: the world blurs and Resume, Restart and Home
## appear. If the controller is unplugged, the game pauses itself and asks
## for it back.

const HOME_SCENE: String = "res://ui/title_screen.tscn"

var is_open: bool = false
var blur: ColorRect
var blur_material: ShaderMaterial
var tiles_holder: Control
var resume: MenuTile
var unplugged_notice: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	blur = ColorRect.new()
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur_material = ShaderMaterial.new()
	blur_material.shader = preload("res://ui/soft_blur.gdshader")
	blur.material = blur_material
	add_child(blur)
	build_tiles()
	build_unplugged_notice()
	Input.joy_connection_changed.connect(on_joy_connection_changed)


func build_tiles() -> void:
	tiles_holder = MenuScreen.new()
	add_child(tiles_holder)
	tiles_holder.make_heading("Paused", 170)
	var row: HBoxContainer = tiles_holder.make_tile_row(380)
	var home: MenuTile = tiles_holder.make_tile("Home", "home", PaintColours.PURPLE)
	resume = tiles_holder.make_tile("Play on", "resume", PaintColours.ORANGE, Vector2(360, 360))
	var restart: MenuTile = tiles_holder.make_tile("Restart", "restart", PaintColours.BLUE)
	for tile in [home, resume, restart]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	resume.chosen.connect(close)
	restart.chosen.connect(func(): SceneManager.go_to(get_tree().current_scene.scene_file_path))
	home.chosen.connect(func(): SceneManager.go_to(HOME_SCENE))
	tiles_holder.first_focus = resume
	# Only keeps hold of focus while the pause menu is showing
	tiles_holder.set_process(false)


func build_unplugged_notice() -> void:
	unplugged_notice = Control.new()
	unplugged_notice.set_anchors_preset(Control.PRESET_FULL_RECT)
	unplugged_notice.visible = false
	unplugged_notice.draw.connect(draw_unplugged_notice)
	add_child(unplugged_notice)


func draw_unplugged_notice() -> void:
	var wiggle: float = sin(Time.get_ticks_msec() / 150.0) * 0.05
	unplugged_notice.draw_set_transform(Vector2(960, 470), wiggle, Vector2.ONE)
	unplugged_notice.draw_circle(Vector2.ZERO, 190, Color.WHITE)
	MenuIcons.draw_controller(unplugged_notice, Vector2.ZERO, 300, PaintColours.BLUE)
	unplugged_notice.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font: Font = unplugged_notice.get_theme_default_font()
	var message: String = "Plug the controller back in"
	var width: float = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var baseline: Vector2 = Vector2(960 - width / 2.0, 780)
	unplugged_notice.draw_string_outline(font, baseline, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, 24, Color.WHITE)
	unplugged_notice.draw_string(font, baseline, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, PaintColours.INK)


func _process(_delta: float) -> void:
	if unplugged_notice.visible:
		unplugged_notice.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or SceneManager.is_changing_scene:
		return
	is_open = true
	get_tree().paused = true
	visible = true
	Music.duck(true)
	Sound.play("pop", 0.0, 0.8)
	blur_material.set_shader_parameter("amount", 0.0)
	create_tween().set_ignore_time_scale(true).tween_method(func(amount): blur_material.set_shader_parameter("amount", amount), 0.0, 1.0, 0.25)
	tiles_holder.scale = Vector2(0.85, 0.85)
	tiles_holder.pivot_offset = Vector2(960, 540)
	tiles_holder.modulate.a = 0.0
	var pop_in: Tween = create_tween().set_parallel().set_ignore_time_scale(true)
	pop_in.tween_property(tiles_holder, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_in.tween_property(tiles_holder, "modulate:a", 1.0, 0.2)
	tiles_holder.set_process(true)
	resume.grab_focus_quietly()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	unplugged_notice.visible = false
	tiles_holder.visible = true
	tiles_holder.set_process(false)
	get_tree().paused = false
	Music.duck(false)
	get_viewport().gui_release_focus()


## Home and Restart leave without closing the menu, so the music needs its
## volume back here or it stays quiet in every scene after.
func _exit_tree() -> void:
	if is_open:
		Music.duck(false)


func on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and Input.get_connected_joypads().is_empty():
		open()
		tiles_holder.visible = false
		unplugged_notice.visible = true
	elif connected and unplugged_notice.visible:
		unplugged_notice.visible = false
		tiles_holder.visible = true
		resume.grab_focus_quietly()
		Sound.play("chime", 0.0)
