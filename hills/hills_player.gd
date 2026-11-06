class_name HillsPlayer
extends RefCounted
## One person playing a Hills level: their blob and the paint it is wearing.

var blob: HillsBlob
## The paint the blob is wearing - see PaintMixing.
var paint: String
var colour_tween: Tween


func _init(new_blob: HillsBlob, starting_paint: String) -> void:
	blob = new_blob
	paint = starting_paint
