class_name TaskBanner
extends Control
## The task card across the top of the meadow: a picture for the kind of
## task, the sentence, and progress - letters spelled so far, or drops
## counted.

const CARD_SIZE: Vector2 = Vector2(1240, 124)
const SHOWN_Y: float = 14.0
const HIDDEN_Y: float = -160.0

var task: MeadowTask
var slide_tween: Tween
var flash: float = 0.0


func _ready() -> void:
	size = CARD_SIZE
	position = Vector2((1920 - CARD_SIZE.x) / 2.0, HIDDEN_Y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_task(new_task: MeadowTask) -> void:
	task = new_task
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
	if task == null:
		return
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE.lerp(PaintColours.YELLOW, flash * 0.6)
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, CARD_SIZE))
	draw_task_picture(Vector2(70, CARD_SIZE.y / 2.0))
	var font: Font = get_theme_default_font()
	var progress_width: float = progress_area_width(font)
	draw_task_text(font, CARD_SIZE.x - 170 - progress_width)
	draw_progress(font, progress_width)


## Shrinks long sentences to fit, and wraps onto two lines as a last resort.
func draw_task_text(font: Font, available_width: float) -> void:
	for font_size in range(46, 33, -2):
		if font.get_string_size(task.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available_width:
			draw_string(font, Vector2(140, CARD_SIZE.y / 2.0 + font_size * 0.35), task.text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
			return
	draw_multiline_string(font, Vector2(140, CARD_SIZE.y / 2.0 - 8), task.text, HORIZONTAL_ALIGNMENT_LEFT,
		available_width, 34, 2, PaintColours.INK)


func progress_area_width(font: Font) -> float:
	match task.type:
		"spell":
			return task.word.length() * 50.0 + 30.0
		"collect":
			return 190.0
	return 0.0


func draw_progress(font: Font, progress_width: float) -> void:
	var left: float = CARD_SIZE.x - progress_width
	if task.type == "spell":
		for letter_index in task.word.length():
			var slot_centre: Vector2 = Vector2(left + letter_index * 50.0 + 20.0, CARD_SIZE.y / 2.0)
			if letter_index < task.letters_done:
				var letter: String = task.word[letter_index]
				var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x
				draw_string(font, slot_centre + Vector2(-width / 2.0, 18), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 50,
					PaintColours.RAINBOW[letter_index % PaintColours.RAINBOW.size()])
			else:
				draw_line(slot_centre + Vector2(-16, 26), slot_centre + Vector2(16, 26), Color(0.75, 0.75, 0.8), 6.0, true)
	elif task.type == "collect":
		var counter: String = "%d / %d" % [task.collected, task.count]
		draw_string(font, Vector2(left, CARD_SIZE.y / 2.0 + 18), counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 50,
			PaintMixing.colour_of(task.paint).darkened(0.25))


func draw_task_picture(centre: Vector2) -> void:
	var picture_colour: Color = PaintColours.BLUE
	if task.paint != "":
		picture_colour = PaintMixing.colour_of(task.paint)
	draw_circle(centre, 46, picture_colour.lightened(0.6))
	var font: Font = get_theme_default_font()
	match task.type:
		"make", "collect":
			draw_colored_polygon(PackedVector2Array([centre + Vector2(-20, -8), centre + Vector2(0, -42), centre + Vector2(20, -8)]), picture_colour)
			draw_circle(centre + Vector2(0, 4), 23, picture_colour)
		"spell":
			draw_string(font, centre + Vector2(-34, 15), "Abc", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, PaintColours.INK)
		"sum":
			draw_string(font, centre + Vector2(-30, 15), "1+2", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, PaintColours.INK)
		"visit":
			MenuIcons.draw_icon(self, "hills", centre, 60, PaintColours.GREEN.darkened(0.2))
		"rainbow":
			for stripe_index in 6:
				draw_arc(centre + Vector2(0, 14), 34 - stripe_index * 5, PI, TAU, 16, PaintColours.RAINBOW[stripe_index], 5.0, true)
