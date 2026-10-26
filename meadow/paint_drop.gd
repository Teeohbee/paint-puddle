class_name PaintDrop
extends Area2D
## A little drop of paint sitting in the grass, bobbing. Drive into it to
## collect it.

signal blob_entered(drop: PaintDrop)

const RADIUS: float = 26.0

var paint_name: String = "blue"
var magnet_radius: float = RADIUS + 56.0
var bob_time: float = randf() * TAU
var wobble_tween: Tween
var is_leaving: bool = false


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS * 0.8
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is MeadowBlob and not is_leaving:
			blob_entered.emit(self))


func pop_in(delay: float) -> void:
	scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func wobble() -> void:
	if wobble_tween != null:
		wobble_tween.kill()
	wobble_tween = create_tween()
	for swing in [0.35, -0.3, 0.2, -0.1, 0.0]:
		wobble_tween.tween_property(self, "rotation", swing, 0.07)


func leave() -> void:
	is_leaving = true
	remove_from_group("magnets")
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 60, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
	tween.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	bob_time += delta
	queue_redraw()


func _draw() -> void:
	var colour: Color = PaintMixing.colour_of(paint_name)
	var lift: float = sin(bob_time * 3.0) * 4.0
	draw_set_transform(Vector2(0, RADIUS * 0.9), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, RADIUS * 0.9, Color(0.1, 0.25, 0.05, 0.25))
	draw_set_transform(Vector2(0, lift), 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-RADIUS * 0.86, -RADIUS * 0.5), Vector2(0, -RADIUS * 2.1),
		Vector2(RADIUS * 0.86, -RADIUS * 0.5)]), colour)
	draw_circle(Vector2.ZERO, RADIUS, colour)
	draw_circle(Vector2(-RADIUS * 0.35, -RADIUS * 0.3), RADIUS * 0.24, Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
