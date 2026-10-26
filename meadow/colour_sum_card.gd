class_name ColourSumCard
extends Control
## Shows a mix as a picture sum: a red blob + a yellow blob = an orange blob,
## with the words underneath. Pops in at the top of the screen, then goes.

const CARD_SIZE: Vector2 = Vector2(820, 190)
const SECONDS_SHOWN: float = 2.8
const SHOWN_Y: float = 160.0
const HIDDEN_Y: float = -230.0

var first_paint: String = "red"
var second_paint: String = "yellow"
var result_paint: String = "orange"
var show_tween: Tween


func _ready() -> void:
	size = CARD_SIZE
	position = Vector2((1920 - CARD_SIZE.x) / 2.0, HIDDEN_Y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_sum(first: String, second: String, result: String) -> void:
	first_paint = first
	second_paint = second
	result_paint = result
	queue_redraw()
	if show_tween != null:
		show_tween.kill()
	show_tween = create_tween()
	show_tween.tween_property(self, "position:y", SHOWN_Y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	show_tween.tween_interval(SECONDS_SHOWN)
	show_tween.tween_property(self, "position:y", HIDDEN_Y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _draw() -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE
	card.set_corner_radius_all(40)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, CARD_SIZE))
	var font: Font = get_theme_default_font()
	var slots: Array[float] = [150.0, 410.0, 670.0]
	var paints: Array[String] = [first_paint, second_paint, result_paint]
	for slot_index in 3:
		var centre: Vector2 = Vector2(slots[slot_index], 78)
		var colour: Color = PaintMixing.colour_of(paints[slot_index])
		draw_circle(centre, 52, colour.darkened(0.3))
		draw_circle(centre, 46, colour)
		draw_circle(centre + Vector2(-16, -16), 10, Color(1, 1, 1, 0.5))
		draw_centred_text(font, PaintMixing.word_for(paints[slot_index]), Vector2(centre.x, 172), 36, colour.darkened(0.35))
	draw_centred_text(font, "+", Vector2(280, 100), 80, PaintColours.INK)
	draw_centred_text(font, "=", Vector2(540, 100), 80, PaintColours.INK)


func draw_centred_text(font: Font, text: String, baseline_centre: Vector2, font_size: int, colour: Color) -> void:
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, baseline_centre - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
