class_name RescueCloud
extends Node2D
## A fluffy cloud that floats up out of the cloud sea to catch a fallen blob
## and carry it gently back to the ground it came from.

const SECONDS_TO_CATCH: float = 0.45
const SECONDS_TO_CARRY: float = 1.3

var puff_time: float = 0.0


## safe_spot is where the blob's centre ends up.
static func rescue(blob: HillsBlob, parent: Node, safe_spot: Vector2) -> void:
	var cloud: RescueCloud = RescueCloud.new()
	parent.add_child(cloud)
	cloud.carry(blob, safe_spot)


func carry(blob: HillsBlob, safe_spot: Vector2) -> void:
	blob.is_being_carried = true
	blob.velocity = Vector2.ZERO
	var catch_spot: Vector2 = blob.position + Vector2(0, 40)
	position = catch_spot + Vector2(0, 260)
	modulate.a = 0.0
	Sound.play("wobble", 0.0, 1.3)
	var catching: Tween = create_tween().set_parallel()
	catching.tween_property(self, "position", catch_spot + Vector2(0, 60), SECONDS_TO_CATCH).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	catching.tween_property(self, "modulate:a", 1.0, 0.2)
	await catching.finished
	blob.look.squash_stretch.kick(Vector2(-10, 10))
	var start: Vector2 = blob.position
	var carrying: Tween = create_tween()
	carrying.tween_method(func(how_far: float):
		var along: Vector2 = start.lerp(safe_spot, how_far)
		var lift: float = sin(how_far * PI) * 120.0
		blob.position = along - Vector2(0, lift)
		position = blob.position + Vector2(0, 60), 0.0, 1.0, SECONDS_TO_CARRY).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await carrying.finished
	blob.is_being_carried = false
	blob.velocity = Vector2.ZERO
	Sound.play("pop", 0.0, 0.8)
	var vanish: Tween = create_tween().set_parallel()
	vanish.tween_property(self, "scale", Vector2(1.4, 0.6), 0.3)
	vanish.tween_property(self, "modulate:a", 0.0, 0.3)
	vanish.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	puff_time += delta
	queue_redraw()


func _draw() -> void:
	var puffs: Array[Vector3] = [Vector3(-70, 10, 40), Vector3(-30, -12, 50), Vector3(25, -14, 52), Vector3(70, 8, 40), Vector3(0, 14, 48)]
	for puff in puffs:
		draw_circle(Vector2(puff.x, puff.y + 10), puff.z, Color(0.7, 0.8, 0.95, 0.5))
	for puff_index in puffs.size():
		var puff: Vector3 = puffs[puff_index]
		var breathe: float = 1.0 + 0.04 * sin(puff_time * 4.0 + puff_index)
		draw_circle(Vector2(puff.x, puff.y), puff.z * breathe, Color.WHITE)
	draw_circle(Vector2(-22, -2), 5, PaintColours.INK)
	draw_circle(Vector2(22, -2), 5, PaintColours.INK)
	draw_arc(Vector2(0, 6), 12, 0.4, PI - 0.4, 10, PaintColours.INK, 3.0, true)
