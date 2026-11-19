class_name ClockAnswerCards
extends Control
## The three answers under the clock on a read card. Each says a time in
## words, with its part of the day, am/pm and a sun or moon. Left and right
## move between them; the runner asks which one is picked. A wrong pick
## fades away, so it can't be picked again.

const CARD_SIZE: Vector2 = Vector2(300, 124)
const GAP: float = 16.0
const WORDS_FONT_SIZE: int = 40
const SMALL_FONT_SIZE: int = 26

## The times on the cards, left to right.
var answers: Array[int] = []
## How see-through each card is, 1 = solid. Faded cards are out.
var opacities: Array[float] = []
var chosen_index: int = 0
var shows_digital_helper: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(CARD_SIZE.x * 3 + GAP * 2, CARD_SIZE.y)


func show_answers(new_answers: Array[int], digital_helper: bool) -> void:
	answers = new_answers.duplicate()
	opacities.clear()
	for answer in answers:
		opacities.append(1.0)
	shows_digital_helper = digital_helper
	chosen_index = 0
	visible = true
	queue_redraw()


func hide_answers() -> void:
	answers.clear()
	visible = false


## Moves the choice left (-1) or right (1), skipping faded cards.
func move_choice(direction: int) -> void:
	var index: int = chosen_index
	for attempt in answers.size():
		index += direction
		if index < 0 or index >= answers.size():
			return
		if is_still_in(index):
			chosen_index = index
			Sound.play("move", 0.02, 1.1)
			queue_redraw()
			return


func chosen_answer() -> int:
	return answers[chosen_index]


func is_still_in(index: int) -> bool:
	return opacities[index] > 0.99


## Fades the chosen card out and moves the choice to one still in.
func fade_chosen() -> void:
	var faded_index: int = chosen_index
	var fade: Tween = create_tween()
	fade.tween_method(func(opacity: float) -> void: set_opacity(faded_index, opacity), 1.0, 0.0, 0.6)
	opacities[faded_index] = 0.98
	for index in answers.size():
		if is_still_in(index):
			chosen_index = index
			break
	queue_redraw()


func set_opacity(index: int, opacity: float) -> void:
	if index < opacities.size():
		opacities[index] = minf(opacity, 0.98)
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	for index in answers.size():
		if opacities[index] <= 0.0:
			continue
		draw_answer_card(font, index, Vector2(index * (CARD_SIZE.x + GAP), 0))


func draw_answer_card(font: Font, index: int, top_left: Vector2) -> void:
	var opacity: float = opacities[index]
	var time: int = answers[index]
	var is_chosen: bool = index == chosen_index and is_still_in(index)
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color(1, 1, 1, opacity)
	card.set_corner_radius_all(30)
	card.shadow_color = Color(0, 0, 0, 0.18 * opacity)
	card.shadow_size = 8
	card.shadow_offset = Vector2(0, 4)
	card.anti_aliasing = true
	if is_chosen:
		card.set_border_width_all(8)
		card.border_color = PaintColours.YELLOW
	draw_style_box(card, Rect2(top_left, CARD_SIZE))
	var ink: Color = Color(PaintColours.INK, opacity)
	var words: String = ClockTime.time_words(time)
	var words_size: int = fitting_font_size(font, words, CARD_SIZE.x - 30)
	draw_centred(font, words, top_left + Vector2(CARD_SIZE.x / 2.0, 50), words_size, ink)
	var small_line: String = "%s · %s" % [part_of_the_day_words(time), ClockTime.am_or_pm(time)]
	if shows_digital_helper:
		small_line += " · " + ClockTime.digital_text(time)
	draw_centred(font, small_line, top_left + Vector2(CARD_SIZE.x / 2.0 + 18, 96), SMALL_FONT_SIZE, Color(PaintColours.INK, 0.6 * opacity))
	var small_width: float = font.get_string_size(small_line, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
	draw_sun_or_moon(top_left + Vector2(CARD_SIZE.x / 2.0 - small_width / 2.0 - 4, 87), time, opacity)


## "in the morning", "at night"...
static func part_of_the_day_words(time: int) -> String:
	var part: String = ClockTime.part_of_the_day(time)
	if part == "night":
		return "at night"
	return "in the " + part


func draw_sun_or_moon(centre: Vector2, time: int, opacity: float) -> void:
	if ClockTime.part_of_the_day(time) == "night":
		draw_circle(centre, 13, Color(PaintColours.YELLOW.lightened(0.3), opacity))
		draw_circle(centre + Vector2(6, -4), 11, Color(1, 1, 1, opacity))
		return
	for ray in 8:
		var direction: Vector2 = Vector2.from_angle(TAU * ray / 8.0)
		draw_line(centre + direction * 13, centre + direction * 18, Color(PaintColours.ORANGE, opacity), 3.0)
	draw_circle(centre, 10, Color(PaintColours.YELLOW, opacity))


func fitting_font_size(font: Font, text: String, room: float) -> int:
	for font_size in range(WORDS_FONT_SIZE, 23, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
			return font_size
	return 24


func draw_centred(font: Font, text: String, centre: Vector2, font_size: int, colour: Color) -> void:
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, centre + Vector2(-text_width / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
