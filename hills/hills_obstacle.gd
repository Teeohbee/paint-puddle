class_name HillsObstacle
extends Area2D
## A Medium obstacle standing on the ground: a rock, a log, a snowball. A blob
## that runs into it is bumped back a little and carries on - nothing is lost.
## It then ignores that blob for a moment, so it can never trap anyone.
## Jumping over it avoids the bump. The look comes from the level's scene.

const RADIUS: float = 38.0
const BUMP_DISTANCE: float = 140.0
const BUMP_SECONDS: float = 0.25
const BUMP_HOP_SPEED: float = 400.0
const IGNORE_SECONDS: float = 1.2

var look: String = "rock"
## When each blob (by instance id) may be bumped again, in milliseconds.
var ignoring_until: Dictionary = {}


func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -RADIUS + 6)
	add_child(collision)
	body_entered.connect(on_body_entered)


func on_body_entered(body: Node2D) -> void:
	if not body is HillsBlob or body.is_being_carried:
		return
	var now: int = Time.get_ticks_msec()
	if ignoring_until.get(body.get_instance_id(), 0) > now:
		return
	ignoring_until[body.get_instance_id()] = now + int(IGNORE_SECONDS * 1000.0)
	bump(body)


func bump(blob: HillsBlob) -> void:
	var side: float = 1.0 if blob.position.x >= position.x else -1.0
	blob.velocity.y = -BUMP_HOP_SPEED
	blob.look.squash_stretch.kick(Vector2(-12, 10))
	Sound.play("pop", 0.0, 0.6)
	var slide: Tween = blob.create_tween()
	slide.tween_property(blob, "position:x", blob.position.x + side * BUMP_DISTANCE, BUMP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	match look:
		"snowball":
			# Outlined and shaded underneath, so it shows up against snow
			draw_circle(Vector2(0, -RADIUS + 6), RADIUS + 3, Color(0.5, 0.6, 0.82))
			draw_circle(Vector2(0, -RADIUS + 6), RADIUS, Color(0.97, 0.98, 1.0))
			draw_arc(Vector2(0, -RADIUS + 6), RADIUS - 5, 0.2, 2.9, 16, Color(0.74, 0.8, 0.94), 8.0, true)
		"log":
			draw_rect(Rect2(-RADIUS - 8, -RADIUS * 1.15, RADIUS * 2 + 16, RADIUS * 1.15 + 4), Color(0.55, 0.36, 0.2))
			draw_circle(Vector2(RADIUS + 8, -RADIUS * 0.55), RADIUS * 0.55, Color(0.78, 0.58, 0.36))
			draw_arc(Vector2(RADIUS + 8, -RADIUS * 0.55), RADIUS * 0.3, 0.0, TAU, 20, Color(0.55, 0.36, 0.2), 3.0, true)
		"shell":
			var fan: PackedVector2Array = PackedVector2Array([Vector2(0, 4)])
			for point_index in 13:
				var angle: float = lerpf(PI, TAU, point_index / 12.0)
				fan.append(Vector2(cos(angle), sin(angle)) * RADIUS * 1.1 + Vector2(0, 4))
			draw_colored_polygon(fan, Color(1.0, 0.76, 0.8))
			for ridge in 5:
				var ridge_angle: float = lerpf(PI + 0.3, TAU - 0.3, ridge / 4.0)
				draw_line(Vector2(0, 4), Vector2(cos(ridge_angle), sin(ridge_angle)) * RADIUS * 1.1 + Vector2(0, 4), Color(0.9, 0.55, 0.65), 3.0)
		_:
			var rock: PackedVector2Array = PackedVector2Array()
			for point_index in 14:
				var angle: float = lerpf(PI, TAU, point_index / 13.0)
				rock.append(Vector2(cos(angle) * RADIUS * 1.2, sin(angle) * RADIUS * 1.05 + 4))
			draw_colored_polygon(rock, Color(0.6, 0.62, 0.66))
			draw_circle(Vector2(-14, -RADIUS * 0.55), 7.0, Color(0.78, 0.8, 0.84))
