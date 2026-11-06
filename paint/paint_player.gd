class_name PaintPlayer
extends RefCounted
## One person painting: their blob, what its paint is made of, and which
## brush on the canvas is theirs.

var blob: MeadowBlob
## What the blob's paint is made of. The blob only knows the paint's name,
## and printer black made from all three inks shares its name with black
## ink, so the bits are kept here for mixing and painting.
var paint_bits: int = 0
var last_brush_position: Vector2
## Which of the canvas's brushes this player paints with.
var brush_number: int = 0
## The button that throws a splat in Splat party. The usual one hears any pad;
## once two are playing each gets their own - see PlayerControls.
var act_action: StringName = PlayerControls.ACT_ACTION
var seconds_until_next_throw: float = 0.0


func _init(new_blob: MeadowBlob, new_brush_number: int, brush_position: Vector2) -> void:
	blob = new_blob
	brush_number = new_brush_number
	last_brush_position = brush_position
