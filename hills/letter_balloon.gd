class_name LetterBalloon
extends Area2D
## A balloon with a letter on it, bobbing on its string. Touch it to pop it.

signal popped(balloon: LetterBalloon)

const RADIUS: float = 44.0

var letter: String = "A"
var letter_index: int = 0
var paint_colour: Color = PaintColours.RED
var bob_time: float = randf() * TAU
var anchor: Vector2


func _ready() -> void:
	anchor = position
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS + 6
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is HillsBlob:
			pop())


func pop() -> void:
	set_deferred("monitoring", false)
	PaintSplash.burst(get_parent(), position, paint_colour, 16, 520)
	Sound.play("pop", 0.0, 1.0 + letter_index * 0.1)
	popped.emit(self)
	queue_free()


func _process(delta: float) -> void:
	bob_time += delta
	position = anchor + Vector2(sin(bob_time * 1.3) * 4.0, sin(bob_time * 2.0) * 8.0)
	queue_redraw()


func _draw() -> void:
	var string_points: PackedVector2Array = PackedVector2Array()
	for point_index in 8:
		var along: float = point_index / 7.0
		string_points.append(Vector2(sin(bob_time * 3.0 + along * 4.0) * 5.0 * along, RADIUS * 1.15 + along * 60.0))
	draw_polyline(string_points, Color(0.4, 0.4, 0.45), 2.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.15))
	draw_circle(Vector2.ZERO, RADIUS + 3, paint_colour.darkened(0.25))
	draw_circle(Vector2.ZERO, RADIUS, paint_colour)
	draw_circle(Vector2(-RADIUS * 0.35, -RADIUS * 0.4), RADIUS * 0.2, Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, RADIUS * 1.18), Vector2(7, RADIUS * 1.18), Vector2(0, RADIUS * 1.05)]),
		paint_colour.darkened(0.25))
	var font: Font = get_tree().root.theme.default_font
	var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 56).x
	draw_string_outline(font, Vector2(-width / 2.0, 20), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 56, 12, paint_colour.darkened(0.4))
	draw_string(font, Vector2(-width / 2.0, 20), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color.WHITE)
