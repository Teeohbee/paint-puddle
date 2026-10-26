extends Control
## The splash: a drop of paint falls, splats, and the logo pops out of the
## splat a letter at a time. Any button skips to the title.

const TITLE_SCENE: String = "res://ui/title_screen.tscn"
const DROP_FALL_SECONDS: float = 0.55
const SECONDS_BETWEEN_LETTERS: float = 0.07
const SPLAT_CENTRE: Vector2 = Vector2(960, 560)

var logo: RainbowLogo
var drop_position: Vector2 = Vector2(960, -80)
var drop_visible: bool = true
var splat_progress: float = 0.0
var droplets: Array[Dictionary] = []
var has_left: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	logo = RainbowLogo.new()
	logo.position = SPLAT_CENTRE + Vector2(0, 40)
	add_child(logo)
	logo.hide_all_letters()
	play_the_splash()


func play_the_splash() -> void:
	await get_tree().create_timer(0.35).timeout
	var fall: Tween = create_tween()
	fall.tween_property(self, "drop_position", SPLAT_CENTRE, DROP_FALL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	splat()
	await pop_in_letters()
	await get_tree().create_timer(1.1).timeout
	leave()


func splat() -> void:
	drop_visible = false
	Sound.play("splat", 0.0)
	for droplet_index in 18:
		var direction: Vector2 = Vector2.from_angle(randf_range(PI * 1.05, TAU - 0.05))
		droplets.append({
			"position": SPLAT_CENTRE,
			"velocity": direction * randf_range(380, 900),
			"radius": randf_range(8, 20),
			"colour": PaintColours.RAINBOW[droplet_index % PaintColours.RAINBOW.size()],
		})
	var spread: Tween = create_tween()
	spread.tween_property(self, "splat_progress", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pop_in_letters() -> void:
	var letter_number: int = 0
	for letter_index in logo.visible_letter_indices():
		var pop: Tween = create_tween()
		pop.tween_method(logo.set_letter_size.bind(letter_index), 0.0, 1.0, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.play("pop", 0.0, 0.8 + letter_number * 0.06)
		letter_number += 1
		await get_tree().create_timer(SECONDS_BETWEEN_LETTERS).timeout


func _process(delta: float) -> void:
	for droplet in droplets:
		droplet.velocity.y += 1800.0 * delta
		droplet.position += droplet.velocity * delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), PaintColours.CREAM)
	if splat_progress > 0.0:
		var puddle_size: Vector2 = Vector2(760, 150) * splat_progress
		draw_set_transform(SPLAT_CENTRE + Vector2(0, 150), 0.0, Vector2(1.0, puddle_size.y / puddle_size.x))
		draw_circle(Vector2.ZERO, puddle_size.x / 2.0, PaintColours.BLUE.lerp(PaintColours.CREAM, 0.75))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for droplet in droplets:
		draw_circle(droplet.position, droplet.radius, droplet.colour)
	if drop_visible:
		draw_paint_drop(drop_position)


func draw_paint_drop(tip_bottom: Vector2) -> void:
	var radius: float = 46.0
	var centre: Vector2 = tip_bottom - Vector2(0, radius)
	draw_colored_polygon(PackedVector2Array([centre + Vector2(-radius * 0.86, -radius * 0.5),
		centre + Vector2(0, -radius * 2.3), centre + Vector2(radius * 0.86, -radius * 0.5)]), PaintColours.BLUE)
	draw_circle(centre, radius, PaintColours.BLUE)
	draw_circle(centre + Vector2(-radius * 0.35, -radius * 0.3), radius * 0.22, Color(1, 1, 1, 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("act") or event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		leave()


func leave() -> void:
	if has_left:
		return
	has_left = true
	SceneManager.go_to(TITLE_SCENE)
