class_name JoinScreen
extends MenuScreen
## Two players: each presses A on their own pad, one after the other. The first
## becomes player one and the second player two. Back (or Escape) gives up.

var first_device: int = -1
var prompt: Label


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Two players", 150)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_preset(Control.PRESET_TOP_WIDE)
	prompt.offset_top = 640
	prompt.add_theme_font_size_override("font_size", 72)
	prompt.add_theme_color_override("font_color", PaintColours.INK)
	prompt.add_theme_color_override("font_outline_color", Color.WHITE)
	prompt.add_theme_constant_override("outline_size", 26)
	add_child(prompt)
	var way_out: Label = Label.new()
	way_out.text = "Only one controller? Press B to go back"
	way_out.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	way_out.set_anchors_preset(Control.PRESET_TOP_WIDE)
	way_out.offset_top = 800
	way_out.add_theme_font_size_override("font_size", 48)
	way_out.add_theme_color_override("font_color", PaintColours.INK)
	way_out.add_theme_color_override("font_outline_color", Color.WHITE)
	way_out.add_theme_constant_override("outline_size", 18)
	add_child(way_out)
	show_prompt()


func show_prompt() -> void:
	prompt.text = "Player 1 - press A" if first_device < 0 else "Player 2 - press A"


func _draw() -> void:
	var left_colour: Color = PaintColours.RED
	var right_colour: Color = PaintColours.BLUE if first_device >= 0 else Color(1, 1, 1, 0.6)
	MenuIcons.draw_controller(self, Vector2(700, 400), 280, left_colour)
	MenuIcons.draw_controller(self, Vector2(1220, 400), 280, right_colour)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		on_pad_pressed(event)
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func on_pad_pressed(event: InputEventJoypadButton) -> void:
	if event.pressed and event.button_index == JOY_BUTTON_B:
		get_viewport().set_input_as_handled()
		go_back()
		return
	if not event.pressed or event.button_index != JOY_BUTTON_A:
		return
	if first_device < 0:
		first_device = event.device
		Sound.play("pop")
		show_prompt()
		queue_redraw()
	elif event.device != first_device:
		if PlayerSession.choose_two_players(first_device, event.device):
			Sound.play("pick")
			go_back()


func go_back() -> void:
	SceneManager.go_to("res://ui/play_menu.tscn")
