class_name PaintSplash
extends Node2D
## A one-off burst of paint droplets that fly out, slow down, shrink and go.

const LIFETIME_SECONDS: float = 0.7

var droplets: Array[Dictionary] = []
var age: float = 0.0


static func burst(parent: Node, at_position: Vector2, colour: Color, droplet_count: int = 14, speed: float = 520.0) -> PaintSplash:
	var splash: PaintSplash = PaintSplash.new()
	splash.position = at_position
	for droplet_index in droplet_count:
		var direction: Vector2 = Vector2.from_angle(TAU * droplet_index / droplet_count + randf_range(-0.2, 0.2))
		splash.droplets.append({
			"position": Vector2.ZERO,
			"velocity": direction * speed * randf_range(0.5, 1.0),
			"radius": randf_range(6.0, 13.0),
			"colour": colour,
		})
	parent.add_child(splash)
	return splash


func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME_SECONDS:
		queue_free()
		return
	for droplet in droplets:
		droplet.position += droplet.velocity * delta
		droplet.velocity *= pow(0.02, delta)
	queue_redraw()


func _draw() -> void:
	var how_old: float = age / LIFETIME_SECONDS
	for droplet in droplets:
		draw_circle(droplet.position, droplet.radius * (1.0 - how_old * how_old), droplet.colour)
