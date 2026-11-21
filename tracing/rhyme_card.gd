class_name RhymeCard
extends Control
## The card across the top while tracing: the letter big in a circle, and
## the rhyme school says with it, for a grown-up to say along.

const CARD_SIZE: Vector2 = Vector2(1240, 124)
const LETTER_FONT_SIZE: int = 72
const RHYME_FONT_SIZE: int = 36

var letter: String = ""
var rhyme: String = ""
var letter_colour: Color = PaintColours.BLUE
var flash: float = 0.0


func _ready() -> void:
	size = CARD_SIZE
	position = Vector2((1920 - CARD_SIZE.x) / 2.0, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_letter(new_letter: String, new_rhyme: String, colour: Color) -> void:
	letter = new_letter
	rhyme = new_rhyme
	letter_colour = colour
	queue_redraw()


func celebrate() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = move_toward(flash, 0.0, delta * 1.5)
		queue_redraw()


func _draw() -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE.lerp(PaintColours.YELLOW, flash * 0.6)
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, CARD_SIZE))
	var font: Font = get_theme_default_font()
	var circle_centre: Vector2 = Vector2(70, CARD_SIZE.y / 2.0)
	draw_circle(circle_centre, 46, letter_colour.lightened(0.6))
	var letter_size: Vector2 = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_FONT_SIZE)
	draw_string(font, circle_centre + Vector2(-letter_size.x / 2.0, font.get_ascent(LETTER_FONT_SIZE) * 0.5 - 6),
		letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_FONT_SIZE, letter_colour.darkened(0.35))
	var text_left: float = 140.0
	var text_width: float = CARD_SIZE.x - text_left - 40.0
	var line_count: int = 1 if font.get_string_size(rhyme, HORIZONTAL_ALIGNMENT_LEFT, -1, RHYME_FONT_SIZE).x <= text_width else 2
	var line_height: float = font.get_height(RHYME_FONT_SIZE)
	var top: float = (CARD_SIZE.y - line_height * line_count) / 2.0 + font.get_ascent(RHYME_FONT_SIZE)
	draw_multiline_string(font, Vector2(text_left, top), rhyme, HORIZONTAL_ALIGNMENT_LEFT, text_width, RHYME_FONT_SIZE, 2, PaintColours.INK)
