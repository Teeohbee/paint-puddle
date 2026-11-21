class_name Fireflies
extends Node2D
## Fireflies drifting and twinkling over the Evening Meadow (Medium), in place
## of the day's cloud shadows. Just to look at: nothing to catch.

const MEADOW_SIZE: Vector2 = Vector2(1920, 1080)
const FIREFLY_COUNT: int = 22
const GLOW: Color = Color(1.0, 0.95, 0.55)

var fireflies: Array[Dictionary] = []
var time: float = 0.0


func _ready() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 77
	for firefly_index in FIREFLY_COUNT:
		fireflies.append({
			"home": Vector2(random.randf_range(120, MEADOW_SIZE.x - 120), random.randf_range(140, MEADOW_SIZE.y - 120)),
			"wander": random.randf_range(30.0, 70.0),
			"speed": random.randf_range(0.15, 0.35),
			"twinkle_speed": random.randf_range(0.8, 1.6),
			"offset": random.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	for firefly in fireflies:
		var t: float = time * firefly.speed + firefly.offset
		var centre: Vector2 = firefly.home + Vector2(sin(t * 1.3), cos(t)) * firefly.wander
		# Bright for a moment, then almost gone
		var brightness: float = pow(0.5 + 0.5 * sin(time * firefly.twinkle_speed + firefly.offset), 3.0)
		draw_circle(centre, 16.0, Color(GLOW, 0.12 * brightness))
		draw_circle(centre, 8.0, Color(GLOW, 0.3 * brightness))
		draw_circle(centre, 3.5, Color(GLOW, 0.2 + 0.8 * brightness))
