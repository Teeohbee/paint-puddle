# PROTOTYPE - saves look book stills of every clock face variant.
# godot --path . -s res://clock/prototype_look/capture_look.gd -- <out dir>
extends SceneTree

const SHOTS := [
	["rung1-7am", 0, 7 * 60],
	["rung7-2-50pm", 6, 14 * 60 + 50],
	["rung4-quarter-past-9pm", 3, 21 * 60 + 15],
	["rung6-25-past-6pm", 5, 18 * 60 + 25],
]


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var prototype = load("res://clock/prototype_look/clock_look_prototype.tscn").instantiate()
	root.add_child(prototype)
	await create_timer(0.3).timeout
	for variant in range(3, 5):
		for shot in SHOTS:
			prototype.show_state(variant, shot[1], shot[2])
			await create_timer(0.25).timeout
			root.get_texture().get_image().save_png("%s/%s-%s.png" % [out, "ABCDE"[variant], shot[0]])
	quit()
