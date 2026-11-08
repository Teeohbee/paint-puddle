extends CanvasLayer
## Every screen change goes through here. A rainbow of paint splats covers
## the screen, the scene swaps underneath, and the splats shrink away. Nothing
## can be pressed while the splats are moving.

signal scene_changed(new_scene: Node)

const SECONDS_TO_COVER: float = 0.4
const SECONDS_TO_UNCOVER: float = 0.45
const SPLAT_COLUMNS: int = 5
const SPLAT_ROWS: int = 3
const SCREEN_SIZE: Vector2 = Vector2(1920, 1080)

var is_changing_scene: bool = false
## 0 = screen clear, 1 = screen covered in paint
var coverage: float = 0.0:
	set(new_coverage):
		coverage = new_coverage
		curtain.queue_redraw()

var curtain: Control
var splats: Array[Dictionary] = []


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.theme = GameTheme.build()
	curtain = Control.new()
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.draw.connect(draw_splats)
	add_child(curtain)
	lay_out_splats()


func lay_out_splats() -> void:
	var cell_size: Vector2 = SCREEN_SIZE / Vector2(SPLAT_COLUMNS, SPLAT_ROWS)
	var colour_index: int = 0
	for row in SPLAT_ROWS:
		for column in SPLAT_COLUMNS:
			var centre: Vector2 = (Vector2(column, row) + Vector2(0.5, 0.5)) * cell_size
			centre += Vector2(randf_range(-40, 40), randf_range(-40, 40))
			splats.append({
				"centre": centre,
				"radius": cell_size.length() * 0.62,
				"colour": PaintColours.RAINBOW[colour_index % PaintColours.RAINBOW.size()],
				"start_at": randf_range(0.0, 0.35),
				"droplet_angles": [randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU)],
			})
			colour_index += 1
	splats.shuffle()


func draw_splats() -> void:
	if coverage <= 0.0:
		return
	for splat in splats:
		var own_progress: float = clampf((coverage - splat.start_at) / (1.0 - splat.start_at), 0.0, 1.0)
		if own_progress <= 0.0:
			continue
		var radius: float = splat.radius * ease(own_progress, 0.4)
		var rim_colour: Color = splat.colour.darkened(0.15)
		curtain.draw_circle(splat.centre, radius, rim_colour)
		for droplet_angle in splat.droplet_angles:
			var droplet_centre: Vector2 = splat.centre + Vector2.from_angle(droplet_angle) * radius * 1.08
			curtain.draw_circle(droplet_centre, radius * 0.2, rim_colour)
			curtain.draw_circle(droplet_centre, radius * 0.2 - 8.0, splat.colour)
		curtain.draw_circle(splat.centre, radius - 10.0, splat.colour)


## Returns false if a change is already happening, so double presses are harmless.
func go_to(scene_path: String) -> bool:
	if is_changing_scene:
		return false
	is_changing_scene = true
	change_scene_behind_the_paint(scene_path)
	return true


func change_scene_behind_the_paint(scene_path: String) -> void:
	freeze(get_tree().current_scene)
	Sound.play("splat")
	await tween_coverage_to(1.0, SECONDS_TO_COVER)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	var new_scene: Node = get_tree().current_scene
	freeze(new_scene)
	Engine.time_scale = GameSettings.game_speed() if new_scene.is_in_group("gameplay") else 1.0
	scene_changed.emit(new_scene)
	await tween_coverage_to(0.0, SECONDS_TO_UNCOVER)
	unfreeze(new_scene)
	is_changing_scene = false


func tween_coverage_to(target_coverage: float, seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(self, "coverage", target_coverage, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func freeze(scene: Node) -> void:
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED


func unfreeze(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.process_mode = Node.PROCESS_MODE_INHERIT
