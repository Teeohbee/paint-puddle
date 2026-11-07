class_name SplatPal
extends WanderingBlob
## A blob that potters about in Splat party to be splatted. It starts clean
## and keeps what it's been hit with, until the sponge washes the picture.

var paint_bits: int = 0


func _init() -> void:
	wander_area = Rect2(160, 160, 1600, 600)
	position = Vector2(randf_range(300, 1600), randf_range(200, 700))


## Takes on a new paint with a big happy wobble.
func take_paint(new_bits: int, paint_name: String) -> void:
	paint_bits = new_bits
	set_paint_colour(PaintMixing.colour_of(paint_name))
	look.squash_stretch.kick(Vector2(-14, 12))


func wash() -> void:
	take_paint(0, "clean")
