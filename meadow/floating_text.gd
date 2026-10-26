class_name FloatingText
extends Node2D
## Words or numbers that pop up, float and fade. Used for counting drops
## and for "Well done!".

var text: String = ""
var font_size: int = 64
var colour: Color = PaintColours.INK
var lifetime_seconds: float = 1.1
var rise: float = 90.0
var age: float = 0.0
var start_position: Vector2


static func show_at(parent: Node, at_position: Vector2, shown_text: String, shown_colour: Color,
		size: int = 64, seconds: float = 1.1, rise_distance: float = 90.0) -> FloatingText:
	var floating: FloatingText = FloatingText.new()
	floating.text = shown_text
	floating.colour = shown_colour
	floating.font_size = size
	floating.lifetime_seconds = seconds
	floating.rise = rise_distance
	floating.position = at_position
	floating.start_position = at_position
	parent.add_child(floating)
	return floating


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime_seconds:
		queue_free()
		return
	var how_far: float = age / lifetime_seconds
	position = start_position - Vector2(0, rise * ease(how_far, 0.4))
	var pop: float = minf(age / 0.18, 1.0)
	scale = Vector2.ONE * (0.4 + 0.6 * ease(pop, -2.0) + 0.1 * sin(pop * PI))
	modulate.a = clampf((lifetime_seconds - age) / 0.3, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var font: Font = get_tree().root.theme.default_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline: Vector2 = Vector2(-width / 2.0, font_size * 0.35)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_size / 4, Color.WHITE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
