class_name SplatParty
extends PaintStudio
## Splat party: Paint's paper, puddles, fountain and sponge, but moving
## doesn't paint. A flings a splat of the blob's paint instead.

var paint_colour_set_before: String = ""


func _init() -> void:
	paints_trails = false
	# Paint colours only; put the Paint menu's choice back on the way out
	paint_colour_set_before = PaintStudio.colour_set
	PaintStudio.colour_set = "paint"


func _exit_tree() -> void:
	PaintStudio.colour_set = paint_colour_set_before


func configure_controls_hint() -> void:
	controls_hint.shows_jump = false
	controls_hint.shows_act_button = true
