class_name SquashStretchSpring
extends RefCounted
## A springy scale that always wants to return to (1, 1). Kick it to squash
## or stretch the blob; it wobbles past rest a couple of times, then settles.

var stiffness: float = 320.0
var damping: float = 11.0
var scale: Vector2 = Vector2.ONE
var velocity: Vector2 = Vector2.ZERO


func kick(scale_velocity: Vector2) -> void:
	velocity += scale_velocity


func step(delta: float) -> void:
	var pull_towards_rest: Vector2 = (Vector2.ONE - scale) * stiffness
	var friction: Vector2 = velocity * damping
	velocity += (pull_towards_rest - friction) * delta
	scale += velocity * delta
