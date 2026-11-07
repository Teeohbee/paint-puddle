class_name SplatThing
extends SpelledThing
## One of the Meadow's word characters (a dog, a rocket, a caterpillar...)
## hopping about Splat party to be splatted. It keeps what it's been hit
## with, as a tint, until the sponge washes the picture.

## Below this the paper ends and the puddle row begins.
const PAPER_BOTTOM: float = 780.0
const TINT_STRENGTH: float = 0.75

var paint_bits: int = 0


func _init() -> void:
	is_good_spot = func(spot: Vector2) -> bool: return spot.y < PAPER_BOTTOM


## Takes on a new paint with a spin and a happy hop.
func take_paint(new_bits: int, paint_name: String) -> void:
	paint_bits = new_bits
	var tint: Color = Color.WHITE.lerp(PaintMixing.colour_of(paint_name), TINT_STRENGTH) if new_bits != 0 else Color.WHITE
	picture.modulate = tint
	celebrate()


func wash() -> void:
	# Already clean: nothing to celebrate
	if paint_bits != 0:
		take_paint(0, "clean")


func celebrate() -> void:
	if is_jumping or is_leaving:
		return
	is_jumping = true
	var jump: Tween = create_tween()
	jump.tween_property(self, "jump_lift", 40.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	jump.parallel().tween_property(self, "spin", TAU, 0.36)
	jump.tween_property(self, "jump_lift", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await jump.finished
	# Waving goodbye has taken over the pose; leave it be
	if is_leaving:
		return
	spin = 0.0
	is_jumping = false


## A hit that changes nothing still gets a little hop.
func wobble() -> void:
	celebrate()
