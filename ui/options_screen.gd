extends MenuScreen
## Music and sound volumes for everyone. Holding all four face buttons for
## three seconds opens the grown-up settings: game speed, gap size, jump
## help and resetting progress.

const SECONDS_TO_HOLD_FOR_GROWN_UPS: float = 3.0
const FACE_BUTTONS: Array[JoyButton] = [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]

var rows: VBoxContainer
var grown_up_rows: Array[OptionRow] = []
var grown_up_heading: Label
var seconds_held: float = 0.0
var grown_ups_unlocked: bool = false
var hold_ring: Control
var reset_row: OptionRow
var reset_confirm_seconds_left: float = 0.0


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Options", 60)
	rows = VBoxContainer.new()
	rows.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rows.offset_top = 185
	rows.add_theme_constant_override("separation", 12)
	add_child(rows)

	var music: OptionRow = add_slider_row("Music", "music", PaintColours.PURPLE, "music_volume", 1, "")
	add_slider_row("Sounds", "sound", PaintColours.ORANGE, "sound_volume", 1, "")
	grown_up_heading = Label.new()
	grown_up_heading.text = "Grown-up settings"
	grown_up_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grown_up_heading.add_theme_font_size_override("font_size", 40)
	grown_up_heading.visible = false
	rows.add_child(grown_up_heading)
	grown_up_rows.append(add_slider_row("Game speed", "speed", PaintColours.GREEN, "game_speed_percent", 10, "%"))
	grown_up_rows.append(add_slider_row("Gap size", "gap", PaintColours.BLUE, "gap_size_percent", 10, "%"))
	grown_up_rows.append(add_slider_row("Jump help", "jump", PaintColours.YELLOW, "coyote_time_milliseconds", 50, "ms"))
	reset_row = add_button_row("Reset progress", "reset", PaintColours.RED)
	reset_row.chosen.connect(on_reset_chosen)
	grown_up_rows.append(reset_row)
	for row in grown_up_rows:
		row.visible = false

	var back: OptionRow = add_button_row("Back", "back", PaintColours.PURPLE)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))

	hold_ring = Control.new()
	hold_ring.position = Vector2(1780, 70)
	hold_ring.draw.connect(draw_hold_ring)
	add_child(hold_ring)
	first_focus = music
	music.grab_focus.call_deferred()


func add_slider_row(word: String, icon_kind: String, colour: Color, setting_name: String,
		step: int, suffix: String) -> OptionRow:
	var row: OptionRow = OptionRow.new()
	var limits: Dictionary = GameSettings.SETTING_LIMITS[setting_name]
	row.word = word
	row.icon_kind = icon_kind
	row.paint_colour = colour
	row.smallest = limits.smallest
	row.largest = limits.largest
	row.step = step
	row.value_suffix = suffix
	row.value = GameSettings.get_setting(setting_name)
	row.value_changed.connect(func(new_value): GameSettings.set_setting(setting_name, new_value))
	rows.add_child(row)
	return row


func add_button_row(word: String, icon_kind: String, colour: Color) -> OptionRow:
	var row: OptionRow = OptionRow.new()
	row.word = word
	row.icon_kind = icon_kind
	row.paint_colour = colour
	row.is_slider = false
	rows.add_child(row)
	return row


func on_reset_chosen() -> void:
	if reset_confirm_seconds_left > 0.0:
		GameSettings.reset_progress()
		reset_row.message = "Progress reset"
		reset_confirm_seconds_left = 0.0
		Sound.play("chime", 0.0)
		return
	reset_row.message = "Press again to reset"
	reset_confirm_seconds_left = 3.0


func _process(delta: float) -> void:
	super(delta)
	if reset_confirm_seconds_left > 0.0:
		reset_confirm_seconds_left -= delta
		if reset_confirm_seconds_left <= 0.0:
			reset_row.message = ""
	if grown_ups_unlocked:
		return
	if all_face_buttons_held():
		seconds_held += delta
		if seconds_held >= SECONDS_TO_HOLD_FOR_GROWN_UPS:
			unlock_grown_up_settings()
	else:
		seconds_held = 0.0
	hold_ring.queue_redraw()


func all_face_buttons_held() -> bool:
	if Input.is_physical_key_pressed(KEY_G):
		return true
	for device in Input.get_connected_joypads():
		var holding_all: bool = true
		for button in FACE_BUTTONS:
			if not Input.is_joy_button_pressed(device, button):
				holding_all = false
		if holding_all:
			return true
	return false


func unlock_grown_up_settings() -> void:
	grown_ups_unlocked = true
	seconds_held = 0.0
	hold_ring.queue_redraw()
	Sound.play("chime", 0.0)
	grown_up_heading.visible = true
	for row in grown_up_rows:
		row.visible = true
		row.modulate.a = 0.0
		create_tween().tween_property(row, "modulate:a", 1.0, 0.3)


func draw_hold_ring() -> void:
	if seconds_held <= 0.0:
		return
	var how_far: float = seconds_held / SECONDS_TO_HOLD_FOR_GROWN_UPS
	hold_ring.draw_circle(Vector2.ZERO, 50, Color(1, 1, 1, 0.85))
	hold_ring.draw_arc(Vector2.ZERO, 42, -PI / 2.0, -PI / 2.0 + TAU * how_far, 48, PaintColours.PURPLE, 12, true)
	MenuIcons.draw_padlock(hold_ring, Vector2(0, -6), 50, PaintColours.INK)
