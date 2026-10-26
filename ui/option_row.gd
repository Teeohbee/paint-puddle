class_name OptionRow
extends Control
## One line of the options screen. A slider row shows its value as paint
## dots and changes with left and right. A button row does something when
## picked.

signal value_changed(new_value: int)
signal chosen

const ROW_SIZE: Vector2 = Vector2(1000, 90)

var word: String = ""
var icon_kind: String = "music"
var paint_colour: Color = PaintColours.BLUE
var is_slider: bool = true
var value: int = 0
var smallest: int = 0
var largest: int = 10
var step: int = 1
## Shown after the dots, e.g. "70%". Empty shows nothing.
var value_suffix: String = ""
## Shown in place of the word for a moment, e.g. "Press again to reset".
var message: String = ""
var bounce_time: float = 0.0


func _init() -> void:
	custom_minimum_size = ROW_SIZE
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _ready() -> void:
	focus_entered.connect(func():
		Sound.play("move")
		bounce_time = 0.0)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(grab_focus)


func _process(delta: float) -> void:
	if has_focus():
		bounce_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if is_slider and event.is_action_pressed("ui_left"):
		change_value_by(-step)
		accept_event()
	elif is_slider and event.is_action_pressed("ui_right"):
		change_value_by(step)
		accept_event()
	elif not is_slider and event.is_action_pressed("ui_accept"):
		Sound.play("pick", 0.0)
		chosen.emit()
		accept_event()


func change_value_by(amount: int) -> void:
	var new_value: int = clampi(value + amount, smallest, largest)
	if new_value == value:
		Sound.play("locked", 0.0)
		return
	value = new_value
	value_changed.emit(value)
	Sound.play("pop", 0.0, 0.7 + 0.6 * float(value - smallest) / maxf(largest - smallest, 1))


func _draw() -> void:
	var is_focused: bool = has_focus()
	var lift: float = -absf(sin(bounce_time * 4.0)) * 5.0 if is_focused else 0.0
	var card: Rect2 = Rect2(Vector2(0, lift), size)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.92) if is_focused else Color(1, 1, 1, 0.86)
	box.set_corner_radius_all(36)
	box.anti_aliasing = true
	if is_focused:
		box.set_border_width_all(8)
		box.border_color = paint_colour
	draw_style_box(box, card)
	var icon_centre: Vector2 = card.position + Vector2(70, size.y / 2.0)
	draw_circle(icon_centre, 38, paint_colour)
	MenuIcons.draw_icon(self, icon_kind, icon_centre, 46, Color.WHITE)
	var font: Font = get_theme_default_font()
	var shown_word: String = message if message != "" else word
	draw_string(font, card.position + Vector2(130, size.y / 2.0 + 16), shown_word, HORIZONTAL_ALIGNMENT_LEFT, 380, 44, PaintColours.INK)
	if is_slider:
		draw_value_dots(card, font)


func draw_value_dots(card: Rect2, font: Font) -> void:
	var dot_count: int = (largest - smallest) / step + 1
	var filled_count: int = (value - smallest) / step + 1
	var dots_left: float = 520.0
	var dots_width: float = 340.0
	var spacing: float = dots_width / maxf(dot_count - 1, 1)
	for dot_index in dot_count:
		var dot_centre: Vector2 = card.position + Vector2(dots_left + dot_index * spacing, size.y / 2.0)
		var is_filled: bool = dot_index < filled_count and not (smallest == 0 and value == 0)
		var radius: float = 15.0 if is_filled else 10.0
		draw_circle(dot_centre, radius, paint_colour if is_filled else Color(0.8, 0.8, 0.82))
	if value_suffix != "":
		draw_string(font, card.position + Vector2(890, size.y / 2.0 + 14), str(value) + value_suffix,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 36, PaintColours.INK)
	if has_focus():
		draw_string(font, card.position + Vector2(470, size.y / 2.0 + 14), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, paint_colour)
		var right_arrow_x: float = 880.0 if value_suffix == "" else 960.0
		draw_string(font, card.position + Vector2(right_arrow_x, size.y / 2.0 + 14), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, paint_colour)
