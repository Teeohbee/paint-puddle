# PROTOTYPE - saves look book stills of every house variant.
# godot --path . -s res://clock/prototype_house/capture_house.gd -- <out dir>
extends SceneTree

const HOURS := [7, 8, 10, 14, 18, 19, 21, 2]


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var prototype = load("res://clock/prototype_house/house_look_prototype.tscn").instantiate()
	root.add_child(prototype)
	await create_timer(0.3).timeout
	for variant in 4:
		for hour in HOURS:
			prototype.show_state(variant, 2, hour * 60)
			await create_timer(0.2).timeout
			root.get_texture().get_image().save_png("%s/%s-%02d.png" % [out, "ABCD"[variant], hour])
	quit()
