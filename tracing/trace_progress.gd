class_name TraceProgress
extends RefCounted
## How far through tracing a letter: its strokes are painted in order, dot by
## dot, from each stroke's start. A dot paints when the blob comes within
## reach of it. Dots a little way ahead count too, so cutting a corner
## doesn't stall the trace, but nothing further on does, and the next stroke
## waits until this one is done. Leaving the path never unpaints anything.

## How many dots past the next one also count.
const LOOKAHEAD: int = 3

var strokes: Array[PackedVector2Array] = []
var stroke_index: int = 0
## The next dot to paint in the current stroke.
var dot_index: int = 0


func _init(letter_strokes: Array[PackedVector2Array]) -> void:
	strokes = letter_strokes


## Paints the dots in reach and says how many were painted.
func paint_near(blob_position: Vector2, reach: float) -> int:
	if is_finished():
		return 0
	var stroke: PackedVector2Array = strokes[stroke_index]
	var furthest_in_reach: int = -1
	for ahead in range(dot_index, mini(dot_index + LOOKAHEAD + 1, stroke.size())):
		if stroke[ahead].distance_to(blob_position) < reach:
			furthest_in_reach = ahead
	if furthest_in_reach == -1:
		return 0
	var painted: int = furthest_in_reach + 1 - dot_index
	dot_index = furthest_in_reach + 1
	if dot_index >= stroke.size():
		stroke_index += 1
		dot_index = 0
	return painted


func is_finished() -> bool:
	return stroke_index >= strokes.size()


func is_painted(in_stroke: int, at_dot: int) -> bool:
	return in_stroke < stroke_index or (in_stroke == stroke_index and at_dot < dot_index)


## Where to drive next. The last dot of the letter once it's finished.
func next_dot() -> Vector2:
	if is_finished():
		var last_stroke: PackedVector2Array = strokes[strokes.size() - 1]
		return last_stroke[last_stroke.size() - 1]
	return strokes[stroke_index][dot_index]


func painted_count() -> int:
	var count: int = dot_index
	for done_stroke in mini(stroke_index, strokes.size()):
		count += strokes[done_stroke].size()
	return count
