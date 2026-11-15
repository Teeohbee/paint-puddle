# PROTOTYPE - saves look book stills of every tricky face.
# godot --path . -s res://clock/prototype_tricky_faces/capture_tricky_faces.gd -- <out dir>
extends SceneTree

const SHOTS := [
	["rung1-7-oclock", 0, 7 * 60],
	["rung5-quarter-to-3", 4, 14 * 60 + 45],
	["rung7-10-to-3", 6, 14 * 60 + 50],
]


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var prototype = load("res://clock/prototype_tricky_faces/tricky_faces_prototype.tscn").instantiate()
	root.add_child(prototype)
	await create_timer(0.3).timeout
	for face in prototype.FACE_NAMES.size():
		for shot in SHOTS:
			prototype.show_state(face, shot[1], shot[2])
			await create_timer(0.1).timeout
			root.get_texture().get_image().save_png("%s/face%d-%s.png" % [out, face, shot[0]])
	quit()
