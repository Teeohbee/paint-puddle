class_name Hedge
extends StaticBody2D
## A bumpy hedge round the edge of the meadow, so the blob can never leave.

const MEADOW_SIZE: Vector2 = Vector2(1920, 1080)
const HEDGE_THICKNESS: float = 56.0

var bump_centres: Array[Vector2] = []
var bump_radii: Array[float] = []


func _ready() -> void:
	add_wall(Rect2(0, 0, MEADOW_SIZE.x, HEDGE_THICKNESS))
	add_wall(Rect2(0, MEADOW_SIZE.y - HEDGE_THICKNESS, MEADOW_SIZE.x, HEDGE_THICKNESS))
	add_wall(Rect2(0, 0, HEDGE_THICKNESS, MEADOW_SIZE.y))
	add_wall(Rect2(MEADOW_SIZE.x - HEDGE_THICKNESS, 0, HEDGE_THICKNESS, MEADOW_SIZE.y))
	lay_out_bumps()


func add_wall(area: Rect2) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = area.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = area.get_center()
	add_child(collision)


func lay_out_bumps() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7
	var edge_points: Array[Vector2] = []
	var step: float = 34.0
	for x in range(0, int(MEADOW_SIZE.x) + 1, int(step)):
		edge_points.append(Vector2(x, HEDGE_THICKNESS * 0.5))
		edge_points.append(Vector2(x, MEADOW_SIZE.y - HEDGE_THICKNESS * 0.5))
	for y in range(0, int(MEADOW_SIZE.y) + 1, int(step)):
		edge_points.append(Vector2(HEDGE_THICKNESS * 0.5, y))
		edge_points.append(Vector2(MEADOW_SIZE.x - HEDGE_THICKNESS * 0.5, y))
	for point in edge_points:
		bump_centres.append(point + Vector2(random.randf_range(-6, 6), random.randf_range(-6, 6)))
		bump_radii.append(random.randf_range(30, 40))


func _draw() -> void:
	for bump_index in bump_centres.size():
		draw_circle(bump_centres[bump_index] + Vector2(0, 8), bump_radii[bump_index], Color(0.18, 0.4, 0.2))
	for bump_index in bump_centres.size():
		draw_circle(bump_centres[bump_index], bump_radii[bump_index], Color(0.27, 0.55, 0.27))
	for bump_index in bump_centres.size():
		var highlight: Vector2 = bump_centres[bump_index] + Vector2(-8, -10)
		draw_circle(highlight, bump_radii[bump_index] * 0.45, Color(0.4, 0.7, 0.35, 0.6))
