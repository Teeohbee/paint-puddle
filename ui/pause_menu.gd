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
## The pad that opened the menu. With two players only this pad can use it.
var opener_device: int = -1


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
	# Arriving with a pad already missing (it went while on a menu): ask for it straight away
	if PlayerSession.has_missing_pad():
		on_joy_connection_changed.call_deferred(-1, false)


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
	# Its pad lock must not eat the Start press that opens the menu
	tiles_holder.set_process_input(false)


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
	if PlayerSession.has_missing_pad():
		message = "Player %d - press A on your controller" % (PlayerSession.missing_slots[0] + 1)
	if PlayerSession.has_missing_pad():
		var way_out: String = "or press B to stop two players"
		var way_out_width: float = font.get_string_size(way_out, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
		var way_out_baseline: Vector2 = Vector2(960 - way_out_width / 2.0, 860)
		unplugged_notice.draw_string_outline(font, way_out_baseline, way_out, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, 18, Color.WHITE)
		unplugged_notice.draw_string(font, way_out_baseline, way_out, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, PaintColours.INK)
	var width: float = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var baseline: Vector2 = Vector2(960 - width / 2.0, 780)
	unplugged_notice.draw_string_outline(font, baseline, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, 24, Color.WHITE)
	unplugged_notice.draw_string(font, baseline, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, PaintColours.INK)


func _process(_delta: float) -> void:
	if unplugged_notice.visible:
		unplugged_notice.queue_redraw()


## Runs before the menu buttons see anything: with two players, the pad that
## didn't pause can't press things, and a pad that has gone missing is
## replaced by the next A press on a pad nobody is using.
func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if unplugged_notice.visible and PlayerSession.has_missing_pad():
		get_viewport().set_input_as_handled()
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			take_new_pad(event.device)
		elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
			give_up_on_two_players()
		return
	if is_open and PlayerSession.is_two_player() and event.device != opener_device:
		if PlayerSession.is_pad_usable(opener_device):
			get_viewport().set_input_as_handled()


## Only one pad left (or the other player has gone home): B on any pad ends two players
## and goes to the Play menu, so nobody is stuck waiting for a pad that isn't coming.
func give_up_on_two_players() -> void:
	PlayerSession.choose_one_player()
	unplugged_notice.visible = false
	tiles_holder.visible = true
	SceneManager.go_to("res://ui/play_menu.tscn")


func take_new_pad(device: int) -> void:
	if not PlayerSession.rebind(device):
		return
	if PlayerSession.has_missing_pad():
		return
	unplugged_notice.visible = false
	tiles_holder.visible = true
	tiles_holder.set_process_input(true)
	tiles_holder.locked_device = device
	opener_device = device
	resume.grab_focus_quietly()
	Sound.play("chime", 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if is_open:
		close()
	else:
		open(event.device if event is InputEventJoypadButton else -1)


func open(opening_device: int = -1) -> void:
	if is_open or SceneManager.is_changing_scene:
		return
	is_open = true
	opener_device = opening_device
	tiles_holder.locked_device = opening_device
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
	tiles_holder.set_process_input(true)
	resume.grab_focus_quietly()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	unplugged_notice.visible = false
	tiles_holder.visible = true
	tiles_holder.set_process(false)
	tiles_holder.set_process_input(false)
	get_tree().paused = false
	Music.duck(false)
	get_viewport().gui_release_focus()


## Home and Restart leave without closing the menu, so the music needs its
## volume back here or it stays quiet in every scene after.
func _exit_tree() -> void:
	if is_open:
		Music.duck(false)


func on_joy_connection_changed(device: int, connected: bool) -> void:
	var someone_is_missing: bool = PlayerSession.has_missing_pad()
	if not connected and (someone_is_missing or Input.get_connected_joypads().is_empty()):
		open()
		# open() does nothing mid-wipe, so try again once the paint has gone.
		# Hiding the tiles now would leave the next pause with only the notice.
		if not is_open:
			await get_tree().create_timer(SceneManager.SECONDS_TO_UNCOVER + 0.1).timeout
			if PlayerSession.has_missing_pad() or Input.get_connected_joypads().is_empty():
				on_joy_connection_changed(device, false)
			return
		tiles_holder.visible = false
		# Its pad lock would swallow the A press that brings a pad back
		tiles_holder.set_process_input(false)
		unplugged_notice.visible = true
	elif connected and unplugged_notice.visible and not someone_is_missing:
		unplugged_notice.visible = false
		tiles_holder.visible = true
		tiles_holder.set_process_input(true)
		resume.grab_focus_quietly()
		Sound.play("chime", 0.0)
