class_name TraceDrawing
extends Node2D
## A letter to trace, drawn on the grass: white dots still to paint, painted
## dots joined into a solid stroke of paint, a green start dot on the stroke
## being drawn until it's begun, and a ring throbbing on the next dot.

const DOT_RADIUS: float = 11.0
const PAINTED_DOT_RADIUS: float = 15.0
const STROKE_WIDTH: float = 30.0
const START_DOT_RADIUS: float = 18.0
const NEXT_RING_RADIUS: float = 24.0

var progress: TraceProgress
var paint_colour: Color = PaintColours.BLUE
var pulse: float = 0.0


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	if progress == null:
		return
	for stroke_index in progress.strokes.size():
		var stroke: PackedVector2Array = progress.strokes[stroke_index]
		# Painted stretches join up, so it reads as a letter, not dots
		for dot_index in range(1, stroke.size()):
			if progress.is_painted(stroke_index, dot_index):
				draw_line(stroke[dot_index - 1], stroke[dot_index], paint_colour, STROKE_WIDTH, true)
		for dot_index in stroke.size():
			if progress.is_painted(stroke_index, dot_index):
				draw_circle(stroke[dot_index], PAINTED_DOT_RADIUS, paint_colour)
			else:
				draw_circle(stroke[dot_index], DOT_RADIUS, Color(1, 1, 1, 0.85))
				draw_arc(stroke[dot_index], DOT_RADIUS, 0, TAU, 20, PaintColours.INK.lerp(Color.WHITE, 0.5), 2.0, true)
	if progress.is_finished():
		return
	var next_dot: Vector2 = progress.next_dot()
	if progress.dot_index == 0:
		draw_circle(next_dot, START_DOT_RADIUS, PaintColours.GREEN)
	var throb: float = 1.0 + 0.25 * sin(pulse * 6.0)
	draw_arc(next_dot, NEXT_RING_RADIUS * throb, 0, TAU, 32, paint_colour, 5.0, true)
