class_name HillsGround
extends Node2D
## Builds the ground for a level from its pieces: solid hills with a grassy
## top, cut where there are gaps. Also answers "how high is the ground here?"

const START_HEIGHT: float = 760.0
const BOTTOM: float = 1700.0
const GRASS_THICKNESS: float = 26.0

## Each solid stretch of ground, as its top edge from left to right.
var ground_tops: Array[PackedVector2Array] = []
var level_length: float = 0.0
var decorations: Array[Dictionary] = []


func build(pieces: Array, gap_scale: float) -> void:
	var current_top: PackedVector2Array = PackedVector2Array([Vector2(0, START_HEIGHT)])
	var x: float = 0.0
	var y: float = START_HEIGHT
	for piece in pieces:
		match piece.kind:
			"flat":
				x += piece.length
				current_top.append(Vector2(x, y))
			"slope":
				for slope_step in range(1, 11):
					var how_far: float = slope_step / 10.0
					# Eased so slopes start and end gently
					var eased: float = (1.0 - cos(how_far * PI)) / 2.0
					current_top.append(Vector2(x + piece.length * how_far, y + piece.rise * eased))
				x += piece.length
				y += piece.rise
			"step":
				y += piece.rise
				current_top.append(Vector2(x, y))
			"gap":
				ground_tops.append(current_top)
				x += piece.width * gap_scale
				current_top = PackedVector2Array([Vector2(x, y)])
	ground_tops.append(current_top)
	level_length = x
	for top in ground_tops:
		add_solid_ground(top)
	scatter_decorations()


func add_solid_ground(top: PackedVector2Array) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	var shape: CollisionPolygon2D = CollisionPolygon2D.new()
	var outline: PackedVector2Array = top.duplicate()
	outline.append(Vector2(top[top.size() - 1].x, BOTTOM))
	outline.append(Vector2(top[0].x, BOTTOM))
	shape.polygon = outline
	body.add_child(shape)
	add_child(body)


## The height of the ground at x, or INF over a gap.
func height_at(x: float) -> float:
	for top in ground_tops:
		if x < top[0].x or x > top[top.size() - 1].x:
			continue
		for point_index in top.size() - 1:
			var left: Vector2 = top[point_index]
			var right: Vector2 = top[point_index + 1]
			if x >= left.x and x <= right.x:
				if right.x == left.x:
					return minf(left.y, right.y)
				return lerpf(left.y, right.y, (x - left.x) / (right.x - left.x))
	return INF


func scatter_decorations() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = int(level_length)
	var x: float = 40.0
	while x < level_length - 40.0:
		var ground_y: float = height_at(x)
		if ground_y != INF:
			decorations.append({
				"position": Vector2(x, ground_y - GRASS_THICKNESS * 0.4),
				"kind": "flower" if random.randf() < 0.35 else "tuft",
				"colour": PaintColours.RAINBOW[random.randi_range(0, 5)],
			})
		x += random.randf_range(50, 110)


func _draw() -> void:
	for top in ground_tops:
		var body_outline: PackedVector2Array = top.duplicate()
		body_outline.append(Vector2(top[top.size() - 1].x, BOTTOM))
		body_outline.append(Vector2(top[0].x, BOTTOM))
		draw_colored_polygon(body_outline, Color(0.96, 0.83, 0.6))
		draw_pebbles(top)
		draw_polyline(offset_points(top, GRASS_THICKNESS * 0.5 + 4.0), Color(0.3, 0.6, 0.28), GRASS_THICKNESS + 8.0, true)
		draw_polyline(offset_points(top, GRASS_THICKNESS * 0.5), Color(0.45, 0.78, 0.36), GRASS_THICKNESS, true)
		draw_circle(top[0] + Vector2(0, GRASS_THICKNESS * 0.5), GRASS_THICKNESS * 0.6, Color(0.45, 0.78, 0.36))
		draw_circle(top[top.size() - 1] + Vector2(0, GRASS_THICKNESS * 0.5), GRASS_THICKNESS * 0.6, Color(0.45, 0.78, 0.36))
	for decoration in decorations:
		if decoration.kind == "flower":
			var centre: Vector2 = decoration.position - Vector2(0, 16)
			draw_line(decoration.position, centre, Color(0.3, 0.55, 0.25), 3.0, true)
			for petal_index in 5:
				draw_circle(centre + Vector2.from_angle(TAU * petal_index / 5.0) * 7.0, 5.5, decoration.colour)
			draw_circle(centre, 4.5, PaintColours.YELLOW)
		else:
			var base: Vector2 = decoration.position
			for blade in [-6.0, 0.0, 6.0]:
				draw_line(base, base + Vector2(blade, -14 + absf(blade)), Color(0.3, 0.6, 0.28), 3.0, true)


## Moves a line of points straight down, so the grass sits on the ground's top.
func offset_points(points: PackedVector2Array, down: float) -> PackedVector2Array:
	var moved: PackedVector2Array = PackedVector2Array()
	for point in points:
		moved.append(point + Vector2(0, down))
	return moved


func draw_pebbles(top: PackedVector2Array) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = int(top[0].x) + 3
	var left: float = top[0].x
	var right: float = top[top.size() - 1].x
	for pebble_index in int((right - left) / 30.0):
		var x: float = random.randf_range(left + 20, right - 20)
		var y: float = random.randf_range(height_at(x) + 60, START_HEIGHT + 500)
		draw_circle(Vector2(x, y), random.randf_range(5, 12), Color(0.9, 0.75, 0.52))
