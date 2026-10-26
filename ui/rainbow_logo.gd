class_name RainbowLogo
extends Node2D
## Big chunky letters, each a different paint colour, gently bobbing. Letters
## can pop in one at a time, and dip when something lands on them.

@export var text: String = "Paint Puddle"
@export var font_size: int = 170

## How big each letter is drawn, 0 to 1. Used to pop letters in.
var letter_sizes: Array[float] = []
var letter_dips: Array[float] = []
var bob_time: float = 0.0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	var theme_font: Font = get_tree().root.theme.default_font if get_tree().root.theme != null else null
	if theme_font != null:
		font = theme_font
	for letter_index in text.length():
		letter_sizes.append(1.0)
		letter_dips.append(0.0)


func _process(delta: float) -> void:
	bob_time += delta
	for letter_index in letter_dips.size():
		letter_dips[letter_index] = move_toward(letter_dips[letter_index], 0.0, delta * 60.0)
	queue_redraw()


func hide_all_letters() -> void:
	for letter_index in letter_sizes.size():
		letter_sizes[letter_index] = 0.0


## The size comes first so tweens can drive it: tween_method(set_letter_size.bind(index), ...)
func set_letter_size(new_size: float, letter_index: int) -> void:
	letter_sizes[letter_index] = new_size


func dip_letter(letter_index: int) -> void:
	letter_dips[letter_index] = 22.0


func visible_letter_indices() -> Array[int]:
	var indices: Array[int] = []
	for letter_index in text.length():
		if text[letter_index] != " ":
			indices.append(letter_index)
	return indices


func letter_colour(letter_index: int) -> Color:
	var colour_index: int = visible_letter_indices().find(letter_index)
	return PaintColours.RAINBOW[colour_index % PaintColours.RAINBOW.size()]


## Where the middle of a letter is, relative to the logo, before bobbing.
func letter_centre(letter_index: int) -> Vector2:
	var whole_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left: float = -whole_width / 2.0
	var width_before: float = font.get_string_size(text.substr(0, letter_index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var letter_width: float = font.get_string_size(text[letter_index], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return Vector2(left + width_before + letter_width / 2.0, -font_size * 0.33)


func letter_bob(letter_index: int) -> float:
	return sin(bob_time * 2.2 + letter_index * 0.6) * 8.0 + letter_dips[letter_index]


func _draw() -> void:
	for letter_index in visible_letter_indices():
		var letter_size: float = letter_sizes[letter_index]
		if letter_size <= 0.01:
			continue
		var letter: String = text[letter_index]
		var centre: Vector2 = letter_centre(letter_index) + Vector2(0, letter_bob(letter_index))
		var tilt: float = 0.06 if letter_index % 2 == 0 else -0.05
		var letter_width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline_offset: Vector2 = Vector2(-letter_width / 2.0, font_size * 0.33)
		var colour: Color = letter_colour(letter_index)
		draw_set_transform(centre + Vector2(0, 12), tilt, Vector2(letter_size, letter_size))
		draw_string_outline(font, baseline_offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 34, Color(0, 0, 0, 0.18))
		draw_set_transform(centre, tilt, Vector2(letter_size, letter_size))
		draw_string_outline(font, baseline_offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 34, Color.WHITE)
		draw_string_outline(font, baseline_offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 12, colour.darkened(0.3))
		draw_string(font, baseline_offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
