class_name PaintTrail
extends Node2D
## Little paint dots the blob leaves behind as it drives, fading away.

const DISTANCE_BETWEEN_DOTS: float = 22.0
const SECONDS_TO_FADE: float = 1.6

var followed_blob: MeadowBlob
var dots: Array[Dictionary] = []
var last_dot_position: Vector2


func follow(blob: MeadowBlob) -> void:
	followed_blob = blob
	last_dot_position = blob.position


func _process(delta: float) -> void:
	for dot in dots:
		dot.age += delta
	dots = dots.filter(func(dot): return dot.age < SECONDS_TO_FADE)
	if followed_blob != null and followed_blob.position.distance_to(last_dot_position) >= DISTANCE_BETWEEN_DOTS:
		last_dot_position = followed_blob.position
		dots.append({
			"position": followed_blob.position + Vector2(randf_range(-14, 14), 34 + randf_range(-6, 6)),
			"colour": followed_blob.look.paint_colour,
			"radius": randf_range(5.0, 9.0),
			"age": 0.0,
		})
	queue_redraw()


func _draw() -> void:
	for dot in dots:
		var how_faded: float = dot.age / SECONDS_TO_FADE
		var colour: Color = dot.colour
		colour.a = 0.9 * (1.0 - how_faded * how_faded)
		draw_circle(dot.position, dot.radius * (1.0 - how_faded * 0.7), colour)
