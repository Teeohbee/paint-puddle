class_name PaintPot
extends Area2D
## An empty paint pot waiting for one colour, with the colour's name under
## it. Drive in wearing the right paint to fill it. The wrong paint just
## makes it wobble.

signal blob_entered(pot: PaintPot)

const RADIUS: float = 46.0

var paint_name: String = "red"
var is_filled: bool = false
var magnet_radius: float = RADIUS + 50.0
var wobble_tween: Tween
var hint_pulse: float = 0.0


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS * 0.5
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is MeadowBlob:
			blob_entered.emit(self))


func fill() -> void:
	is_filled = true
	scale = Vector2(1.3, 1.3)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func empty() -> void:
	is_filled = false


## Wrong colour: a wobble and a brighter hint of what this pot wants.
func wobble() -> void:
	hint_pulse = 1.0
	if wobble_tween != null:
		wobble_tween.kill()
	wobble_tween = create_tween()
	for swing in [0.25, -0.2, 0.14, -0.08, 0.0]:
		wobble_tween.tween_property(self, "rotation", swing, 0.07)


func _process(delta: float) -> void:
	hint_pulse = move_toward(hint_pulse, 0.0, delta)
	queue_redraw()


func _draw() -> void:
	var colour: Color = PaintMixing.colour_of(paint_name)
	draw_circle(Vector2(0, 8), RADIUS + 6, Color(0.1, 0.25, 0.05, 0.22))
	draw_circle(Vector2.ZERO, RADIUS + 6, Color(0.55, 0.56, 0.6))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.82, 0.83, 0.86))
	if is_filled:
		draw_circle(Vector2.ZERO, RADIUS - 6, colour)
		draw_circle(Vector2(-RADIUS * 0.3, -RADIUS * 0.3), RADIUS * 0.18, Color(1, 1, 1, 0.5))
	else:
		draw_circle(Vector2.ZERO, RADIUS - 6, Color(0.95, 0.95, 0.96))
		var dash_count: int = 12
		var hint_width: float = 5.0 + hint_pulse * 5.0
		for dash_index in dash_count:
			var start_angle: float = TAU * dash_index / dash_count
			draw_arc(Vector2.ZERO, RADIUS - 14, start_angle, start_angle + TAU / dash_count * 0.55, 6, colour, hint_width, true)
		draw_circle(Vector2.ZERO, 10.0 + hint_pulse * 6.0, colour)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var font: Font = ThemeDB.fallback_font if get_tree().root.theme == null else get_tree().root.theme.default_font
	var word: String = PaintMixing.word_for(paint_name)
	var width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	var baseline: Vector2 = Vector2(-width / 2.0, RADIUS + 42)
	draw_string_outline(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 10, Color.WHITE)
	draw_string(font, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, colour.darkened(0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
