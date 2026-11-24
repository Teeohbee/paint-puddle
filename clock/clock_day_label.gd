class_name ClockDayLabel
extends Node2D
## A big word under the clock for the part of the day - morning, afternoon,
## evening or night - with the sun or moon beside it. It follows the hands as
## they move, so winding on shows the day going by. No card asks about it:
## it's how morning and evening start to mean something (am/pm is years off).

const FONT_SIZE: int = 50
const PICTURE_ROOM: float = 62.0

var word: String = "morning"


## Called each frame with the time the hands are showing.
func show_time(minutes_of_the_day: int) -> void:
	var new_word: String = ClockTime.part_of_the_day(minutes_of_the_day)
	if new_word != word:
		word = new_word
		queue_redraw()


func _draw() -> void:
	var font: Font = get_tree().root.theme.default_font if get_tree().root.theme != null else ThemeDB.fallback_font
	var word_width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var left: float = -(PICTURE_ROOM + word_width) / 2.0
	draw_sun_or_moon(Vector2(left + 24, 0))
	var baseline: Vector2 = Vector2(left + PICTURE_ROOM, FONT_SIZE * 0.35)
	draw_string_outline(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 12, Color.WHITE)
	draw_string(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, PaintColours.INK)


func draw_sun_or_moon(centre: Vector2) -> void:
	if word == "night":
		draw_circle(centre, 22, PaintColours.YELLOW.lightened(0.3))
		draw_circle(centre + Vector2(10, -7), 18, PaintColours.CREAM)
		return
	for ray in 8:
		var direction: Vector2 = Vector2.from_angle(TAU * ray / 8.0)
		draw_line(centre + direction * 22, centre + direction * 30, PaintColours.ORANGE, 5.0)
	draw_circle(centre, 17, PaintColours.YELLOW)
