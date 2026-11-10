class_name MapMagnet
extends RefCounted
## A spot that gently pulls the pointer in when the D-pad is let go: the
## middle of a country. It stands in for the puddles and pots MagnetPicker
## was written for, which only ask for a position and a reach.

var global_position: Vector2 = Vector2.ZERO
var magnet_radius: float = 90.0
## The country this is the middle of.
var target_id: String = ""


func _init(new_position: Vector2 = Vector2.ZERO, new_radius: float = 90.0, new_target_id: String = "") -> void:
	global_position = new_position
	magnet_radius = new_radius
	target_id = new_target_id
