class_name Bush
extends StaticBody2D
## A round bush with berries. Something to steer round.

@export var radius: float = 70.0
@export var berry_colour: Color = Color(0.9, 0.25, 0.4)

var lumps: Array[Vector3] = []


func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius * 0.9
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = int(position.x * 31 + position.y)
	for lump_index in 7:
		var angle: float = TAU * lump_index / 7.0
		lumps.append(Vector3(cos(angle) * radius * 0.45, sin(angle) * radius * 0.4 - radius * 0.15, radius * random.randf_range(0.5, 0.62)))


func _draw() -> void:
	draw_set_transform(Vector2(0, radius * 0.55), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius * 1.05, Color(0.1, 0.25, 0.05, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, -radius * 0.1), radius * 0.85, Color(0.2, 0.45, 0.22))
	for lump in lumps:
		draw_circle(Vector2(lump.x, lump.y), lump.z, Color(0.29, 0.6, 0.3))
	draw_circle(Vector2(0, -radius * 0.2), radius * 0.5, Color(0.29, 0.6, 0.3))
	for lump in lumps:
		draw_circle(Vector2(lump.x - lump.z * 0.25, lump.y - lump.z * 0.3), lump.z * 0.45, Color(0.42, 0.74, 0.38))
	draw_circle(Vector2(-radius * 0.12, -radius * 0.32), radius * 0.26, Color(0.42, 0.74, 0.38))
	for berry_index in 5:
		var berry_position: Vector2 = Vector2.from_angle(berry_index * 1.9) * radius * 0.5 + Vector2(0, -radius * 0.15)
		draw_circle(berry_position, 6.0, berry_colour)
		draw_circle(berry_position + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.7))
