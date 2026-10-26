class_name LetterStone
extends Area2D
## A flat stepping stone with a letter or number painted on it. Drive onto
## it to pick it. A wrong pick only makes it wobble.

signal blob_entered(stone: LetterStone)

const RADIUS: float = 44.0

var value: String = "A"
var paint_colour: Color = PaintColours.BLUE
var magnet_radius: float = RADIUS + 46.0
var wobble_tween: Tween
var is_leaving: bool = false


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS * 0.5
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is MeadowBlob and not is_leaving:
			blob_entered.emit(self))


func pop_in(delay: float) -> void:
	scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func wobble() -> void:
	if wobble_tween != null:
		wobble_tween.kill()
	wobble_tween = create_tween()
	for swing in [0.3, -0.24, 0.16, -0.08, 0.0]:
		wobble_tween.tween_property(self, "rotation", swing, 0.07)


## Picked: jumps up, grows and fades away.
func leave() -> void:
	is_leaving = true
	remove_from_group("magnets")
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.85))
	draw_circle(Vector2.ZERO, RADIUS + 4, Color(0.1, 0.25, 0.05, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.85))
	draw_circle(Vector2.ZERO, RADIUS + 4, Color(0.58, 0.57, 0.62))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.86, 0.85, 0.88))
	draw_circle(Vector2(-RADIUS * 0.3, -RADIUS * 0.35), RADIUS * 0.25, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font: Font = get_tree().root.theme.default_font
	var font_size: int = 60 if value.length() == 1 else 46
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline: Vector2 = Vector2(-width / 2.0, font_size * 0.36)
	draw_string_outline(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Color.WHITE)
	draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, paint_colour)
