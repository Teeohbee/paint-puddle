class_name Confetti
extends Node2D
## Rainbow confetti raining down over the whole screen for a few seconds.

const PIECE_COUNT: int = 160
const LIFETIME_SECONDS: float = 4.0

var pieces: Array[Dictionary] = []
var age: float = 0.0


func _ready() -> void:
	for piece_index in PIECE_COUNT:
		pieces.append({
			"position": Vector2(randf_range(0, 1920), randf_range(-700, -20)),
			"velocity": Vector2(randf_range(-80, 80), randf_range(220, 420)),
			"spin": randf_range(-8, 8),
			"angle": randf_range(0, TAU),
			"colour": PaintColours.RAINBOW[piece_index % PaintColours.RAINBOW.size()],
			"size": Vector2(randf_range(12, 20), randf_range(7, 11)),
			"sway_offset": randf_range(0, TAU),
		})


func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME_SECONDS:
		queue_free()
		return
	for piece in pieces:
		piece.position += piece.velocity * delta + Vector2(sin(age * 3.0 + piece.sway_offset) * 60.0 * delta, 0)
		piece.angle += piece.spin * delta
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf((LIFETIME_SECONDS - age) / 0.6, 0.0, 1.0)
	for piece in pieces:
		var colour: Color = piece.colour
		colour.a = fade
		draw_set_transform(piece.position, piece.angle, Vector2(1.0, absf(cos(age * 4.0 + piece.sway_offset))))
		draw_rect(Rect2(-piece.size / 2.0, piece.size), colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
