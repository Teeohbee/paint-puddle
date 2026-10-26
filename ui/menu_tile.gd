class_name MenuTile
extends Button
## A big friendly menu tile: a picture and a word on a paint-coloured card.
## It grows, glows and bounces when the D-pad lands on it. A locked tile
## shows a padlock and wobbles when picked, and never does anything else.

signal chosen

const CORNER_RADIUS: int = 48

@export var word: String = ""
@export var icon_kind: String = "play"
@export var paint_colour: Color = PaintColours.BLUE
@export var is_locked: bool = false:
	set(new_is_locked):
		is_locked = new_is_locked
		queue_redraw()

var bounce_time: float = 0.0
var scale_tween: Tween
var stay_quiet_on_next_focus: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(300, 300)
	focus_mode = Control.FOCUS_ALL
	flat = true
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	focus_entered.connect(on_focus_entered)
	focus_exited.connect(on_focus_exited)
	pressed.connect(on_pressed)
	mouse_entered.connect(grab_focus)


func _process(delta: float) -> void:
	if has_focus():
		bounce_time += delta
		queue_redraw()


## For the tile a screen starts on: no click sound just for arriving.
func grab_focus_quietly() -> void:
	stay_quiet_on_next_focus = true
	grab_focus()


func on_focus_entered() -> void:
	if not stay_quiet_on_next_focus:
		Sound.play("move")
	stay_quiet_on_next_focus = false
	bounce_time = 0.0
	tween_scale_to(Vector2(1.12, 1.12), 0.25)


func on_focus_exited() -> void:
	tween_scale_to(Vector2.ONE, 0.2)
	queue_redraw()


func on_pressed() -> void:
	if is_locked:
		Sound.play("locked", 0.0)
		var wobble: Tween = create_tween()
		for swing in [0.12, -0.1, 0.07, -0.04, 0.0]:
			wobble.tween_property(self, "rotation", swing, 0.06)
		return
	Sound.play("pick", 0.0)
	scale = Vector2(1.25, 0.9)
	tween_scale_to(Vector2(1.12, 1.12), 0.3)
	chosen.emit()


func tween_scale_to(target_scale: Vector2, seconds: float) -> void:
	if scale_tween != null:
		scale_tween.kill()
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", target_scale, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var is_focused: bool = has_focus()
	var lift: float = -absf(sin(bounce_time * 4.0)) * 8.0 if is_focused else 0.0
	var card: Rect2 = Rect2(Vector2(0, lift), size)
	var card_colour: Color = paint_colour.lerp(Color(0.75, 0.75, 0.78), 0.55) if is_locked else paint_colour
	if is_focused:
		for glow_step in 4:
			var glow: StyleBoxFlat = rounded_box(Color(1, 1, 1, 0.12), CORNER_RADIUS + 8 + glow_step * 6)
			draw_style_box(glow, card.grow(10 + glow_step * 8))
	draw_style_box(rounded_box(Color(0, 0, 0, 0.18), CORNER_RADIUS), Rect2(card.position + Vector2(0, 12), card.size))
	draw_style_box(rounded_box(card_colour.darkened(0.25), CORNER_RADIUS), card)
	draw_style_box(rounded_box(card_colour, CORNER_RADIUS - 6), card.grow(-10))
	if is_focused:
		var outline: StyleBoxFlat = rounded_box(Color(0, 0, 0, 0), CORNER_RADIUS)
		outline.set_border_width_all(10)
		outline.border_color = Color.WHITE
		draw_style_box(outline, card)
	var icon_centre: Vector2 = card.position + Vector2(size.x / 2.0, size.y * 0.42)
	var icon_size: float = minf(size.x, size.y) * 0.42
	MenuIcons.draw_icon(self, icon_kind, icon_centre + Vector2(0, 5), icon_size, Color(0, 0, 0, 0.15))
	MenuIcons.draw_icon(self, icon_kind, icon_centre, icon_size, Color.WHITE)
	if is_locked:
		MenuIcons.draw_padlock(self, card.position + Vector2(size.x * 0.78, size.y * 0.2), size.x * 0.28, PaintColours.INK)
	draw_word(card)


func draw_word(card: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 48
	var word_width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var baseline: Vector2 = card.position + Vector2((size.x - word_width) / 2.0, size.y * 0.86)
	draw_string_outline(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, paint_colour.darkened(0.45))
	draw_string(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func rounded_box(colour: Color, corner_radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(corner_radius)
	box.anti_aliasing = true
	return box
