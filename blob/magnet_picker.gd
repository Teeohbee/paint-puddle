class_name MagnetPicker
extends RefCounted
## Picks which puddle, pot or fountain gently pulls the meadow blob in when
## the D-pad is let go. Ones the blob was steering away from are left alone
## until it has properly left them, so tapping away from a puddle doesn't
## drag it straight back.

var left_behind: Array = []


## Called every frame a direction is held.
func note_steering(blob_position: Vector2, input_direction: Vector2, magnets: Array) -> void:
	for magnet in magnets:
		if not is_in_reach(blob_position, magnet):
			continue
		var is_heading_towards: bool = input_direction.dot(magnet.global_position - blob_position) > 0.0
		if is_heading_towards:
			left_behind.erase(magnet)
		elif not left_behind.has(magnet):
			left_behind.append(magnet)


## Called every frame nothing is held. Returns null when nothing should pull.
func pick(blob_position: Vector2, magnets: Array) -> Object:
	left_behind = left_behind.filter(func(magnet): return magnets.has(magnet) and is_in_reach(blob_position, magnet))
	var nearest_magnet: Object = null
	var nearest_distance: float = INF
	for magnet in magnets:
		var distance: float = blob_position.distance_to(magnet.global_position)
		if is_in_reach(blob_position, magnet) and distance < nearest_distance and not left_behind.has(magnet):
			nearest_magnet = magnet
			nearest_distance = distance
	return nearest_magnet


func is_in_reach(blob_position: Vector2, magnet: Object) -> bool:
	return blob_position.distance_to(magnet.global_position) < magnet.magnet_radius
