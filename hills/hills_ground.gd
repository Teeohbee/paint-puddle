class_name HillsGround
extends Node2D
## Builds the ground for a level from its pieces: solid hills with a grassy
## top, cut where there are gaps. Also answers "how high is the ground here?"
## Colours and what grows on top come from the level's scene - see HillsScenes.

const START_HEIGHT: float = 760.0
const BOTTOM: float = 1700.0
const GRASS_THICKNESS: float = 26.0
const SAFE_DISTANCE_FROM_EDGE: float = 120.0

## Each solid stretch of ground, as its top edge from left to right.
var ground_tops: Array[PackedVector2Array] = []
var level_length: float = 0.0
var decorations: Array[Dictionary] = []
var scene: Dictionary = HillsScenes.SCENES[HillsScenes.DEFAULT_SCENE]


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


## Where a rescued blob is put down: on the stretch of ground nearest x, at
## least SAFE_DISTANCE_FROM_EDGE in from either end so it's not on a lip.
func safe_ground_point_near(x: float) -> Vector2:
	var nearest_top: PackedVector2Array = ground_tops[0]
	var nearest_distance: float = INF
	for top in ground_tops:
		var left: float = top[0].x
		var right: float = top[top.size() - 1].x
		var distance: float = 0.0
		if x < left:
			distance = left - x
		elif x > right:
			distance = x - right
		if distance < nearest_distance:
			nearest_top = top
			nearest_distance = distance
	var safe_left: float = nearest_top[0].x + SAFE_DISTANCE_FROM_EDGE
	var safe_right: float = nearest_top[nearest_top.size() - 1].x - SAFE_DISTANCE_FROM_EDGE
	var safe_x: float = (safe_left + safe_right) / 2.0
	if safe_left <= safe_right:
		safe_x = clampf(x, safe_left, safe_right)
	return Vector2(safe_x, height_at(safe_x))


func scatter_decorations() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = int(level_length)
	var x: float = 40.0
	while x < level_length - 40.0:
		var ground_y: float = height_at(x)
		if ground_y != INF:
			decorations.append({
				"position": Vector2(x, ground_y - GRASS_THICKNESS * 0.4),
				"kind": pick_decoration(random.randf()),
				"colour": PaintColours.RAINBOW[random.randi_range(0, 5)],
			})
		x += random.randf_range(50, 110)


## Which decoration a roll from 0 to 1 lands on, by the scene's weights.
func pick_decoration(roll: float) -> String:
	var weight_so_far: float = 0.0
	for decoration in scene.decorations:
		weight_so_far += decoration[1]
		if roll < weight_so_far:
			return decoration[0]
	return scene.decorations[scene.decorations.size() - 1][0]


func _draw() -> void:
	for top in ground_tops:
		var body_outline: PackedVector2Array = top.duplicate()
		body_outline.append(Vector2(top[top.size() - 1].x, BOTTOM))
		body_outline.append(Vector2(top[0].x, BOTTOM))
		draw_colored_polygon(body_outline, scene.soil)
		draw_pebbles(top)
		draw_polyline(offset_points(top, GRASS_THICKNESS * 0.5 + 4.0), scene.top_edge, GRASS_THICKNESS + 8.0, true)
		draw_polyline(offset_points(top, GRASS_THICKNESS * 0.5), scene.top, GRASS_THICKNESS, true)
		draw_circle(top[0] + Vector2(0, GRASS_THICKNESS * 0.5), GRASS_THICKNESS * 0.6, scene.top)
		draw_circle(top[top.size() - 1] + Vector2(0, GRASS_THICKNESS * 0.5), GRASS_THICKNESS * 0.6, scene.top)
	for decoration in decorations:
		draw_decoration(decoration)


func draw_decoration(decoration: Dictionary) -> void:
	var base: Vector2 = decoration.position
	match decoration.kind:
		"flower":
			var centre: Vector2 = base - Vector2(0, 16)
			draw_line(base, centre, scene.stalks, 3.0, true)
			for petal_index in 5:
				draw_circle(centre + Vector2.from_angle(TAU * petal_index / 5.0) * 7.0, 5.5, decoration.colour)
			draw_circle(centre, 4.5, PaintColours.YELLOW)
		"tuft":
			for blade in [-6.0, 0.0, 6.0]:
				draw_line(base, base + Vector2(blade, -14 + absf(blade)), scene.top_edge, 3.0, true)
		"snow tuft":
			for lump in [Vector3(-9, -2, 8), Vector3(0, -6, 10), Vector3(10, -1, 7)]:
				draw_circle(base + Vector2(lump.x, lump.y), lump.z, Color(1, 1, 1))
		"little pine":
			var tip: Vector2 = base - Vector2(0, 40)
			draw_line(base, base - Vector2(0, 8), Color(0.45, 0.36, 0.34), 5.0, true)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-14, -6), base + Vector2(14, -6), tip]), scene.stalks)
			draw_colored_polygon(PackedVector2Array([tip.lerp(base + Vector2(-14, -6), 0.35), tip.lerp(base + Vector2(14, -6), 0.35), tip]), Color(1, 1, 1))
		"snowman":
			var belly: Vector2 = base - Vector2(0, 14)
			var head: Vector2 = base - Vector2(0, 36)
			draw_circle(belly, 15, Color(1, 1, 1))
			draw_circle(head, 10, Color(1, 1, 1))
			draw_circle(head + Vector2(-4, -2), 1.8, PaintColours.INK)
			draw_circle(head + Vector2(4, -2), 1.8, PaintColours.INK)
			draw_colored_polygon(PackedVector2Array([head + Vector2(0, 0), head + Vector2(0, 4), head + Vector2(11, 2)]), PaintColours.ORANGE)
			for button in 2:
				draw_circle(belly + Vector2(0, -5 + button * 9), 1.8, PaintColours.INK)
		"leaf pile":
			for leaf_index in 4:
				var leaf_colour: Color = HillsScenes.AUTUMN_LEAVES[(leaf_index + int(base.x)) % HillsScenes.AUTUMN_LEAVES.size()]
				HillsBackdrop.draw_leaf(self, base + Vector2(-12 + leaf_index * 8, -3 - (leaf_index % 2) * 4), 8.0, leaf_index * 0.9, leaf_colour)
		"mushroom":
			draw_rect(Rect2(base.x - 3, base.y - 14, 6, 14), Color(0.97, 0.93, 0.85))
			draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -12), base + Vector2(-9, -22), base + Vector2(0, -26), base + Vector2(9, -22), base + Vector2(13, -12)]), Color(0.85, 0.25, 0.22))
			draw_circle(base + Vector2(-5, -18), 2.2, Color(1, 1, 1))
			draw_circle(base + Vector2(5, -20), 2.0, Color(1, 1, 1))
		"shell":
			draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 0), base + Vector2(-8, -8), base + Vector2(0, -12), base + Vector2(8, -8), base + Vector2(9, 0)]), Color(1.0, 0.75, 0.72))
			for rib in [-4.0, 0.0, 4.0]:
				draw_line(base + Vector2(rib * 0.4, -1), base + Vector2(rib, -9), Color(0.92, 0.6, 0.58), 1.5, true)
		"starfish":
			var arms: PackedVector2Array = PackedVector2Array()
			for point_index in 10:
				var reach: float = 11.0 if point_index % 2 == 0 else 4.5
				arms.append(base + Vector2(0, -9) + Vector2.from_angle(-PI / 2.0 + TAU * point_index / 10.0) * reach)
			draw_colored_polygon(arms, PaintColours.ORANGE)
		"dune grass":
			for blade in [-8.0, -3.0, 3.0, 8.0]:
				draw_line(base, base + Vector2(blade * 1.6, -24 + absf(blade)), scene.stalks, 3.0, true)
		"bucket":
			draw_colored_polygon(PackedVector2Array([base + Vector2(-10, -22), base + Vector2(10, -22), base + Vector2(7, 0), base + Vector2(-7, 0)]), PaintColours.BLUE)
			draw_arc(base + Vector2(0, -22), 10, PI, TAU, 8, Color(0.35, 0.35, 0.42), 2.0, true)
			draw_line(base + Vector2(12, -2), base + Vector2(20, -26), Color(0.35, 0.35, 0.42), 3.0, true)
			draw_rect(Rect2(base.x + 14, base.y - 6, 10, 6), PaintColours.YELLOW)
		"acorn":
			draw_circle(base + Vector2(0, -7), 6.5, Color(0.72, 0.5, 0.28))
			draw_rect(Rect2(base.x - 7, base.y - 15, 14, 6), Color(0.45, 0.3, 0.2))
			draw_line(base + Vector2(0, -15), base + Vector2(2, -19), Color(0.45, 0.3, 0.2), 2.0, true)


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
		draw_circle(Vector2(x, y), random.randf_range(5, 12), scene.pebbles)
