class_name MapTaskBanner
extends Control
## The task card across the top of Map mode: a little globe and the sentence.
## It sits to the right of the controls hint, and slides away between tasks.

const CARD_HEIGHT: float = 124.0
const MOST_WIDTH: float = 1050.0
const LEAST_WIDTH: float = 560.0
const SHOWN_Y: float = 14.0
const HIDDEN_Y: float = -160.0
## The card is centred between the controls hint (which ends at about 330) and the globe pill (which starts at 1520).
const AREA_LEFT: float = 380.0
const AREA_WIDTH: float = 1120.0
const TEXT_LEFT: float = 140.0
const TEXT_RIGHT_MARGIN: float = 50.0

var text: String = ""
var card_width: float = MOST_WIDTH
var slide_tween: Tween
var flash: float = 0.0


func _ready() -> void:
	size = Vector2(MOST_WIDTH, CARD_HEIGHT)
	position = Vector2(AREA_LEFT, HIDDEN_Y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_task(new_task: MapTask) -> void:
	text = new_task.text
	var font: Font = get_theme_default_font()
	card_width = clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x + TEXT_LEFT + TEXT_RIGHT_MARGIN, LEAST_WIDTH, MOST_WIDTH)
	size = Vector2(card_width, CARD_HEIGHT)
	position.x = AREA_LEFT + (AREA_WIDTH - card_width) / 2.0
	queue_redraw()
	slide_to(SHOWN_Y)


func hide_task() -> void:
	slide_to(HIDDEN_Y)


func slide_to(y: float) -> void:
	if slide_tween != null:
		slide_tween.kill()
	slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func celebrate() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	flash = move_toward(flash, 0.0, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	if text == "":
		return
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE.lerp(PaintColours.YELLOW, flash * 0.6)
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	var centre: Vector2 = Vector2(70, CARD_HEIGHT / 2.0)
	draw_circle(centre, 46, PaintColours.BLUE.lightened(0.6))
	MenuIcons.draw_icon(self, "map", centre, 70, PaintColours.BLUE.darkened(0.1))
	var font: Font = get_theme_default_font()
	for font_size in range(50, 33, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= card_width - TEXT_LEFT - TEXT_RIGHT_MARGIN:
			draw_string(font, Vector2(TEXT_LEFT, CARD_HEIGHT / 2.0 + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
			return
