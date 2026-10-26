class_name CloudShadows
extends Node2D
## Soft cloud shadows drifting slowly across the meadow.

const MEADOW_SIZE: Vector2 = Vector2(1920, 1080)
const DRIFT_SPEED: float = 18.0

var clouds: Array[Dictionary] = []


func _ready() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 99
	for cloud_index in 4:
		clouds.append({
			"position": Vector2(random.randf_range(-400, MEADOW_SIZE.x), random.randf_range(100, MEADOW_SIZE.y - 100)),
			"size": random.randf_range(180, 300),
		})


func _process(delta: float) -> void:
	for cloud in clouds:
		cloud.position.x += DRIFT_SPEED * delta
		if cloud.position.x - cloud.size * 2.0 > MEADOW_SIZE.x:
			cloud.position.x = -cloud.size * 2.0
	queue_redraw()


func _draw() -> void:
	var shadow: Color = Color(0.1, 0.2, 0.3, 0.06)
	for cloud in clouds:
		var centre: Vector2 = cloud.position
		var size: float = cloud.size
		draw_set_transform(centre, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, size, shadow)
		draw_circle(Vector2(size * 0.8, size * 0.2), size * 0.7, shadow)
		draw_circle(Vector2(-size * 0.8, size * 0.25), size * 0.6, shadow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
