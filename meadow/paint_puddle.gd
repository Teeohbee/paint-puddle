class_name PaintPuddle
extends Area2D
## A puddle of red, yellow or blue paint. Drive through it to pick up the
## paint - or mix it with what's already on the blob.

signal blob_entered(puddle: PaintPuddle)

const RADIUS: float = 78.0

@export var paint_name: String = "red"

## Pull the blob gently onto the puddle when it stops nearby.
var magnet_radius: float = RADIUS + 70.0
var edge_wobbles: Array[float] = []
var ripple_age: float = 99.0
var wobble_time: float = 0.0


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS * 0.45
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(on_body_entered)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = paint_name.hash()
	for point_index in 28:
		edge_wobbles.append(random.randf_range(-0.12, 0.12))


func on_body_entered(body: Node2D) -> void:
	if body is MeadowBlob:
		ripple_age = 0.0
		blob_entered.emit(self)


func _process(delta: float) -> void:
	ripple_age += delta
	wobble_time += delta
	queue_redraw()


func _draw() -> void:
	var colour: Color = PaintMixing.colour_of(paint_name)
	draw_colored_polygon(splat_outline(RADIUS + 5.0), colour.darkened(0.3))
	draw_colored_polygon(splat_outline(RADIUS), colour)
	for droplet_index in 4:
		var angle: float = droplet_index * 1.7 + 0.4
		draw_circle(Vector2.from_angle(angle) * Vector2(RADIUS * 1.25, RADIUS * 0.95), 9.0 + droplet_index * 2.0, colour)
	draw_set_transform(Vector2(-RADIUS * 0.3, -RADIUS * 0.25), -0.4, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, RADIUS * 0.3, Color(1, 1, 1, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ripple_age < 0.8:
		var ripple_radius: float = RADIUS * (0.3 + ripple_age * 1.2)
		draw_arc(Vector2.ZERO, ripple_radius, 0.0, TAU, 40, Color(1, 1, 1, 0.6 * (1.0 - ripple_age / 0.8)), 5.0, true)


## A lumpy, slightly squashed circle, wobbling slowly like wet paint.
func splat_outline(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in edge_wobbles.size():
		var angle: float = TAU * point_index / edge_wobbles.size()
		var lumpiness: float = 1.0 + edge_wobbles[point_index] + 0.02 * sin(wobble_time * 2.0 + point_index)
		points.append(Vector2.from_angle(angle) * Vector2(radius, radius * 0.78) * lumpiness)
	return points
