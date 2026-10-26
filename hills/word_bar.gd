class_name WordBar
extends Control
## The word for this level across the top. Each balloon popped fills in its
## letter in rainbow colours.

const CARD_HEIGHT: float = 120.0

var word: String = ""
var letters_popped: Array[bool] = []
var letter_bounce: Array[float] = []


func set_word(new_word: String) -> void:
	word = new_word
	letters_popped.clear()
	letter_bounce.clear()
	for letter_index in word.length():
		letters_popped.append(false)
		letter_bounce.append(0.0)
	var card_width: float = 520.0 + word.length() * 70.0
	size = Vector2(card_width, CARD_HEIGHT)
	position = Vector2((1920 - card_width) / 2.0, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func pop_letter(letter_index: int) -> void:
	letters_popped[letter_index] = true
	letter_bounce[letter_index] = 1.0


func all_popped() -> bool:
	return not letters_popped.has(false)


func _process(delta: float) -> void:
	for letter_index in letter_bounce.size():
		letter_bounce[letter_index] = move_toward(letter_bounce[letter_index], 0.0, delta * 2.5)
	queue_redraw()


func _draw() -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(40, CARD_HEIGHT / 2.0 + 16), "Pop the letters:", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, PaintColours.INK)
	for letter_index in word.length():
		var slot_centre: Vector2 = Vector2(460 + letter_index * 70.0, CARD_HEIGHT / 2.0)
		var colour: Color = PaintColours.RAINBOW[letter_index % PaintColours.RAINBOW.size()]
		if letters_popped[letter_index]:
			var bounce: float = sin(letter_bounce[letter_index] * PI) * 18.0
			var letter: String = word[letter_index]
			var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
			draw_string(font, slot_centre + Vector2(-width / 2.0, 22 - bounce), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, colour)
		else:
			var faint: Color = colour
			faint.a = 0.35
			var letter: String = word[letter_index]
			var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
			draw_string(font, slot_centre + Vector2(-width / 2.0, 22), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, faint)
