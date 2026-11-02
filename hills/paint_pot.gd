class_name HillsPaintPot
extends Area2D
## A pot of paint floating up high. Jump into it and its paint mixes into
## the blob for the rest of the level. Missing it is fine.

signal touched(pot: HillsPaintPot)

const WIDTH: float = 64.0
const HEIGHT: float = 70.0

var paint_name: String = "blue"
var bob_time: float = randf() * TAU
var anchor: Vector2


func _ready() -> void:
	anchor = position
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = WIDTH * 0.6
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is HillsBlob:
			touch())


func touch() -> void:
	set_deferred("monitoring", false)
	PaintSplash.burst(get_parent(), position, PaintMixing.colour_of(paint_name), 24, 600)
	Sound.play("pop", 0.0, 0.8)
	touched.emit(self)
	queue_free()


func _process(delta: float) -> void:
	bob_time += delta
	position = anchor + Vector2(0, sin(bob_time * 2.2) * 10.0)
	queue_redraw()


func _draw() -> void:
	var paint_colour: Color = PaintMixing.colour_of(paint_name)
	var pot_colour: Color = Color(0.92, 0.92, 0.96)
	var outline_colour: Color = Color(0.35, 0.35, 0.42)
	var half_width: float = WIDTH / 2.0
	var top: float = -HEIGHT / 2.0
	var bottom: float = HEIGHT / 2.0
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(-half_width, top + 10), Vector2(half_width, top + 10),
		Vector2(half_width * 0.85, bottom), Vector2(-half_width * 0.85, bottom),
	])
	draw_colored_polygon(body, pot_colour)
	# The paint label round the middle, and paint spilling over the rim
	draw_rect(Rect2(-half_width * 0.92, top + 26, WIDTH * 0.92, 26), paint_colour)
	draw_rect(Rect2(-half_width - 4, top, WIDTH + 8, 12), paint_colour.darkened(0.2))
	draw_circle(Vector2(-half_width * 0.4, top + 14), 8, paint_colour.darkened(0.2))
	draw_circle(Vector2(half_width * 0.3, top + 18), 10, paint_colour.darkened(0.2))
	body.append(body[0])
	draw_polyline(body, outline_colour, 4.0, true)
	draw_rect(Rect2(-half_width - 4, top, WIDTH + 8, 12), outline_colour, false, 4.0)
