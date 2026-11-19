class_name ClockTaskBanner
extends Control
## The task card across the top of Clock mode, in the Meadow banner's style:
## a little clock, the sentence, and a small line under it for the part of
## the day, am/pm and (on rungs 4-6) the digital time. It also says the
## gentle "try again" messages, then goes back to the task.

const CARD_HEIGHT: float = 140.0
const MOST_WIDTH: float = 1300.0
const LEAST_WIDTH: float = 640.0
const SHOWN_Y: float = 14.0
const HIDDEN_Y: float = -180.0
## Centred in the space right of the controls hint.
const AREA_LEFT: float = 360.0
const AREA_WIDTH: float = 1520.0
const TEXT_LEFT: float = 150.0
const TEXT_RIGHT_MARGIN: float = 50.0
const MAIN_FONT_SIZE: int = 50
const SMALL_FONT_SIZE: int = 32

## The big line, and the small line under it ("" for none).
var main_text: String = ""
var small_text: String = ""
var card_width: float = MOST_WIDTH
var slide_tween: Tween
var flash: float = 0.0


func _ready() -> void:
	size = Vector2(MOST_WIDTH, CARD_HEIGHT)
	position = Vector2(AREA_LEFT, HIDDEN_Y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_text(new_main_text: String, new_small_text: String = "") -> void:
	main_text = new_main_text
	small_text = new_small_text
	var font: Font = get_theme_default_font()
	var main_width: float = font.get_string_size(main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, MAIN_FONT_SIZE).x
	var small_width: float = font.get_string_size(small_text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
	var text_width: float = maxf(main_width, small_width)
	card_width = clampf(text_width + TEXT_LEFT + TEXT_RIGHT_MARGIN, LEAST_WIDTH, MOST_WIDTH)
	size = Vector2(card_width, CARD_HEIGHT)
	position.x = AREA_LEFT + (AREA_WIDTH - card_width) / 2.0
	queue_redraw()
	slide_to(SHOWN_Y)


func hide_card() -> void:
	slide_to(HIDDEN_Y)


func slide_to(y: float) -> void:
	if slide_tween != null:
		slide_tween.kill()
	slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func celebrate() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = move_toward(flash, 0.0, delta * 1.5)
		queue_redraw()


func _draw() -> void:
	if main_text == "":
		return
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE.lerp(PaintColours.YELLOW, flash * 0.6)
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	var picture_centre: Vector2 = Vector2(75, CARD_HEIGHT / 2.0)
	draw_circle(picture_centre, 50, PaintColours.CYAN.lightened(0.6))
	MenuIcons.draw_icon(self, "clock", picture_centre, 78, PaintColours.CYAN.darkened(0.1))
	var font: Font = get_theme_default_font()
	var room_for_text: float = card_width - TEXT_LEFT - TEXT_RIGHT_MARGIN
	var main_baseline: float = CARD_HEIGHT / 2.0 + MAIN_FONT_SIZE * 0.35
	if small_text != "":
		main_baseline -= 20.0
	var font_size: int = fitting_font_size(font, main_text, room_for_text)
	draw_string(font, Vector2(TEXT_LEFT, main_baseline), main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
	if small_text != "":
		draw_string(font, Vector2(TEXT_LEFT, main_baseline + 46), small_text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, Color(PaintColours.INK, 0.6))


func fitting_font_size(font: Font, text: String, room: float) -> int:
	for font_size in range(MAIN_FONT_SIZE, 33, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
			return font_size
	return 34
