class_name Fountain
extends Area2D
## A little fountain. Drive through it to wash the blob clean.

signal blob_entered

const POOL_RADIUS: float = 80.0

var magnet_radius: float = POOL_RADIUS + 60.0
var spray_time: float = 0.0
var splash_age: float = 99.0


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = POOL_RADIUS * 0.45
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is MeadowBlob:
			splash_age = 0.0
			blob_entered.emit())


func _process(delta: float) -> void:
	spray_time += delta
	splash_age += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.8))
	draw_circle(Vector2.ZERO, POOL_RADIUS + 16, Color(0.1, 0.25, 0.05, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.8))
	draw_circle(Vector2.ZERO, POOL_RADIUS + 14, Color(0.62, 0.6, 0.66))
	draw_circle(Vector2.ZERO, POOL_RADIUS + 4, Color(0.78, 0.77, 0.82))
	draw_circle(Vector2.ZERO, POOL_RADIUS - 4, Color(0.55, 0.85, 0.92))
	for ring_index in 3:
		var ring_progress: float = fmod(spray_time * 0.5 + ring_index / 3.0, 1.0)
		draw_arc(Vector2.ZERO, POOL_RADIUS * (0.2 + ring_progress * 0.75), 0, TAU, 32,
			Color(1, 1, 1, 0.5 * (1.0 - ring_progress)), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 16, Color(0.78, 0.77, 0.82))
	for spout_index in 8:
		var phase: float = fmod(spray_time * 1.6 + spout_index / 8.0, 1.0)
		var direction: Vector2 = Vector2.from_angle(TAU * spout_index / 8.0)
		var drop_position: Vector2 = direction * phase * POOL_RADIUS * 0.6 - Vector2(0, sin(phase * PI) * 40.0)
		draw_circle(drop_position, 6.0 * (1.0 - phase * 0.5), Color(0.85, 0.97, 1.0, 0.9))
	if splash_age < 0.5:
		draw_arc(Vector2.ZERO, POOL_RADIUS * (0.5 + splash_age), 0, TAU, 40, Color(1, 1, 1, 0.8 * (1.0 - splash_age * 2.0)), 6.0, true)
