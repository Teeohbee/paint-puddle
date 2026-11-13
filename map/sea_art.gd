class_name SeaArt
extends RefCounted
## Turns the simple SVG paths the sea life was designed with (absolute M, L,
## C and Z only) into outlines Godot can fill, and draws them.

const CURVE_STEPS: int = 8

static var outlines: Dictionary = {}


## outline_of, worked out once per path.
static func outline(path: String) -> PackedVector2Array:
	if not outlines.has(path):
		outlines[path] = outline_of(path)
	return outlines[path]


## "M-40 0 L40 0 C34 18 20 24 0 24Z" -> the points around that shape.
static func outline_of(path: String) -> PackedVector2Array:
	var spaced: String = path
	for letter in ["M", "L", "C", "Z"]:
		spaced = spaced.replace(letter, " %s " % letter)
	var words: PackedStringArray = spaced.split(" ", false)
	var points: PackedVector2Array = PackedVector2Array()
	var index: int = 0
	var command: String = ""
	while index < words.size():
		if words[index] in ["M", "L", "C", "Z"]:
			command = words[index]
			index += 1
			continue
		if command == "C":
			var start: Vector2 = points[points.size() - 1]
			var control_1: Vector2 = Vector2(float(words[index]), float(words[index + 1]))
			var control_2: Vector2 = Vector2(float(words[index + 2]), float(words[index + 3]))
			var end: Vector2 = Vector2(float(words[index + 4]), float(words[index + 5]))
			for step in range(1, CURVE_STEPS + 1):
				points.append(start.bezier_interpolate(control_1, control_2, end, float(step) / CURVE_STEPS))
			index += 6
		else:
			points.append(Vector2(float(words[index]), float(words[index + 1])))
			index += 2
	if points.size() > 1 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	return points


## A filled shape with a darker edge, the look of everything in the sea.
static func draw_shape(canvas: CanvasItem, outline: PackedVector2Array, fill: Color, edge: Color, edge_width: float) -> void:
	canvas.draw_colored_polygon(outline, fill)
	canvas.draw_polyline(outline + PackedVector2Array([outline[0]]), edge, edge_width, true)


## A white wavy line on the water, from left to right. Phase slides the waves along.
static func draw_wave(canvas: CanvasItem, left: Vector2, length: float, wavelength: float, height: float, phase: float, colour: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = int(length / 4.0)
	for step in steps + 1:
		var x: float = length * step / steps
		points.append(left + Vector2(x, sin((x / wavelength + phase) * TAU) * height))
	canvas.draw_polyline(points, colour, width, true)
