class_name ClockAnswerCards
extends Control
## The three answers under the clock on a read card. Each says a time in
## words, with am/pm and a sun or moon under it. Left and right
## move between them; the runner asks which one is picked. A wrong pick
## fades away, so it can't be picked again.

## Three of these and the gaps have to fit between the screen edge and the house.
const CARD_SIZE: Vector2 = Vector2(276, 124)
## Taller with the digital time on its own line under the rest.
const CARD_SIZE_WITH_DIGITAL: Vector2 = Vector2(276, 158)
const GAP: float = 12.0
## Room left and right inside a card for the words, clear of the chosen card's border.
const CARD_PADDING: float = 36.0
## The sun or moon's width plus the space before the words.
const SUN_OR_MOON_ROOM: float = 33.0
const WORDS_FONT_SIZE: int = 40
const SMALL_FONT_SIZE: int = 26

## The times on the cards, left to right.
var answers: Array[int] = []
## How see-through each card is, 1 = solid. Faded cards are out.
var opacities: Array[float] = []
var chosen_index: int = 0
var shows_digital_helper: bool = false
## Where the bottom of the cards sits, so a taller card grows upwards.
var bottom_y: float = 1066.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(CARD_SIZE.x * 3 + GAP * 2, CARD_SIZE.y)


func show_answers(new_answers: Array[int], digital_helper: bool) -> void:
	answers = new_answers.duplicate()
	opacities.clear()
	for answer in answers:
		opacities.append(1.0)
	shows_digital_helper = digital_helper
	size = Vector2(card_size().x * 3 + GAP * 2, card_size().y)
	position.y = bottom_y - card_size().y
	chosen_index = 0
	visible = true
	queue_redraw()


func card_size() -> Vector2:
	if shows_digital_helper:
		return CARD_SIZE_WITH_DIGITAL
	return CARD_SIZE


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
	draw_style_box(card, Rect2(top_left, card_size()))
	var ink: Color = Color(PaintColours.INK, opacity)
	var words: String = ClockTime.time_words(time)
	var words_size: int = fitting_font_size(font, words, CARD_SIZE.x - CARD_PADDING, WORDS_FONT_SIZE)
	draw_centred(font, words, top_left + Vector2(CARD_SIZE.x / 2.0, 50), words_size, ink)
	if shows_digital_helper:
		draw_centred(font, ClockTime.digital_text(time), top_left + Vector2(CARD_SIZE.x / 2.0, 132), SMALL_FONT_SIZE, Color(PaintColours.INK, 0.6 * opacity))
	# The sun or moon and the am or pm after it are centred together.
	var am_or_pm_line: String = small_line(time)
	var small_width: float = font.get_string_size(am_or_pm_line, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
	var line_left: float = top_left.x + (CARD_SIZE.x - SUN_OR_MOON_ROOM - small_width) / 2.0
	draw_sun_or_moon(Vector2(line_left + 12, top_left.y + 87), time, opacity)
	draw_string(font, Vector2(line_left + SUN_OR_MOON_ROOM, top_left.y + 96 + SMALL_FONT_SIZE * 0.35), am_or_pm_line, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, Color(PaintColours.INK, 0.6 * opacity))


## Just "am" or "pm": the sun or moon beside it does the rest.
static func small_line(time: int) -> String:
	return ClockTime.am_or_pm(time)


func draw_sun_or_moon(centre: Vector2, time: int, opacity: float) -> void:
	if ClockTime.part_of_the_day(time) == "night":
		draw_circle(centre, 13, Color(PaintColours.YELLOW.lightened(0.3), opacity))
		draw_circle(centre + Vector2(6, -4), 11, Color(1, 1, 1, opacity))
		return
	for ray in 8:
		var direction: Vector2 = Vector2.from_angle(TAU * ray / 8.0)
		draw_line(centre + direction * 13, centre + direction * 18, Color(PaintColours.ORANGE, opacity), 3.0)
	draw_circle(centre, 10, Color(PaintColours.YELLOW, opacity))


## The biggest size up to largest_size, in steps of two, that fits the room.
func fitting_font_size(font: Font, text: String, room: float, largest_size: int) -> int:
	for font_size in range(largest_size, 17, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
			return font_size
	return 18


func draw_centred(font: Font, text: String, centre: Vector2, font_size: int, colour: Color) -> void:
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, centre + Vector2(-text_width / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
