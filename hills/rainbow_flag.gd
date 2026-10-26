class_name RainbowFlag
extends Area2D
## The finish: a tall pole with a rainbow flag waving at the top.

signal reached

const POLE_HEIGHT: float = 300.0
const FLAG_SIZE: Vector2 = Vector2(150, 96)

var wave_time: float = 0.0
var is_reached: bool = false


func _ready() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(80, POLE_HEIGHT)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -POLE_HEIGHT / 2.0)
	add_child(collision)
	body_entered.connect(func(body):
		if body is HillsBlob and not is_reached:
			is_reached = true
			reached.emit())


func _process(delta: float) -> void:
	wave_time += delta * (3.0 if is_reached else 1.6)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 40, Color(0.2, 0.3, 0.1, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(Vector2.ZERO, Vector2(0, -POLE_HEIGHT), Color(0.55, 0.5, 0.55), 12.0, true)
	draw_circle(Vector2(0, -POLE_HEIGHT - 8), 14, PaintColours.YELLOW)
	var stripe_height: float = FLAG_SIZE.y / 6.0
	var columns: int = 16
	for stripe_index in 6:
		var points: PackedVector2Array = PackedVector2Array()
		for column in columns + 1:
			var along: float = float(column) / columns
			points.append(flag_point(along, stripe_index * stripe_height))
		for column in range(columns, -1, -1):
			var along: float = float(column) / columns
			points.append(flag_point(along, (stripe_index + 1) * stripe_height))
		draw_colored_polygon(points, PaintColours.RAINBOW[stripe_index])


func flag_point(along: float, down: float) -> Vector2:
	var wave: float = sin(wave_time * 4.0 - along * 5.0) * 10.0 * along
	return Vector2(6 + along * FLAG_SIZE.x, -POLE_HEIGHT + down + wave)
