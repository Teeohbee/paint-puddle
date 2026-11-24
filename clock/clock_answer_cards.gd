class_name ClockAnswerCards
extends Control
## The three answers under the clock on a read card. Each says a time in
## words, nothing else - the word under the clock says the part of the day. Left and right
## move between them; the runner asks which one is picked. A wrong pick
## wobbles and greys out where it is, so it can't be picked again.

## Three of these and the gaps have to fit between the screen edge and the house.
const CARD_SIZE: Vector2 = Vector2(276, 124)
const GAP: float = 12.0
## Room left and right inside a card for the words, clear of the chosen card's border.
const CARD_PADDING: float = 36.0
const WORDS_FONT_SIZE: int = 44
## How solid a greyed-out wrong answer stays.
const GREYED_OUT_OPACITY: float = 0.35
const WOBBLE_SECONDS: float = 0.5

## The times on the cards, left to right.
var answers: Array[int] = []
## How see-through each card is, 1 = solid. Greyed-out cards are out.
var opacities: Array[float] = []
var chosen_index: int = 0
## Where the bottom of the cards sits.
var bottom_y: float = 1066.0
var wobbling_index: int = -1
var wobble_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(CARD_SIZE.x * 3 + GAP * 2, CARD_SIZE.y)


func show_answers(new_answers: Array[int]) -> void:
	answers = new_answers.duplicate()
	opacities.clear()
	for answer in answers:
		opacities.append(1.0)
	size = Vector2(CARD_SIZE.x * 3 + GAP * 2, CARD_SIZE.y)
	position.y = bottom_y - CARD_SIZE.y
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


## Wobbles the chosen card, greys it out where it is, and moves the choice
## to one still in.
func grey_out_chosen() -> void:
	var faded_index: int = chosen_index
	var fade: Tween = create_tween()
	fade.tween_method(func(opacity: float) -> void: set_opacity(faded_index, opacity), 1.0, GREYED_OUT_OPACITY, 0.6)
	opacities[faded_index] = 0.98
	wobbling_index = faded_index
	wobble_left = WOBBLE_SECONDS
	for index in answers.size():
		if is_still_in(index):
			chosen_index = index
			break
	queue_redraw()


func set_opacity(index: int, opacity: float) -> void:
	if index < opacities.size():
		opacities[index] = minf(opacity, 0.98)
		queue_redraw()


func _process(delta: float) -> void:
	if wobble_left > 0.0:
		wobble_left = maxf(wobble_left - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	for index in answers.size():
		var top_left: Vector2 = Vector2(index * (CARD_SIZE.x + GAP), 0)
		if index == wobbling_index and wobble_left > 0.0:
			top_left.x += sin(wobble_left * 45.0) * 12.0 * (wobble_left / WOBBLE_SECONDS)
		draw_answer_card(font, index, top_left)


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
	var words_size: int = fitting_font_size(font, words, CARD_SIZE.x - CARD_PADDING, WORDS_FONT_SIZE)
	draw_centred(font, words, top_left + CARD_SIZE / 2.0, words_size, ink)


## The biggest size up to largest_size, in steps of two, that fits the room.
func fitting_font_size(font: Font, text: String, room: float, largest_size: int) -> int:
	for font_size in range(largest_size, 17, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
			return font_size
	return 18


func draw_centred(font: Font, text: String, centre: Vector2, font_size: int, colour: Color) -> void:
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, centre + Vector2(-text_width / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
