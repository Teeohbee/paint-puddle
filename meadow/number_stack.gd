class_name NumberStack
extends Area2D
## A number you can count: a column of squares, one for each, with the
## number on the bottom square. Drive into one and it hops up and follows
## the blob; drive into another and they snap together into one stack of
## both. No faces - these are numbers, not characters.

signal blob_entered(stack: NumberStack)

const SQUARE_SIZE: float = 28.0
const SQUARE_GAP: float = 2.0
const TRAIL_DISTANCE: float = 80.0
## The colours each number is known by, 1 to 10. 7 is a stripe of each
## rainbow colour, 9 is greys and 10 is white with a red edge.
const INDIGO: Color = Color(0.32, 0.24, 0.66)
const VIOLET: Color = Color(0.66, 0.4, 0.88)
const NUMBER_COLOURS: Dictionary = {
	1: PaintColours.RED, 2: PaintColours.ORANGE, 3: PaintColours.YELLOW, 4: PaintColours.GREEN,
	5: PaintColours.BLUE, 6: INDIGO, 8: PaintColours.MAGENTA, 10: Color.WHITE,
}
const SEVEN_STRIPES: Array[Color] = [PaintColours.RED, PaintColours.ORANGE, PaintColours.YELLOW, PaintColours.GREEN,
	PaintColours.BLUE, INDIGO, VIOLET]
const NINE_GREYS: Array[Color] = [Color(0.45, 0.45, 0.5), Color(0.62, 0.62, 0.67), Color(0.78, 0.78, 0.82)]

var value: int = 1:
	set(new_value):
		value = new_value
		queue_redraw()
var magnet_radius: float = 70.0
var is_leaving: bool = false
var blob_to_follow: Node2D
var wobble_tween: Tween
var bob_time: float = randf() * TAU


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 26.0
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body):
		if body is MeadowBlob and not is_leaving and blob_to_follow == null:
			blob_entered.emit(self))


func is_carried() -> bool:
	return blob_to_follow != null


func pop_in(delay: float) -> void:
	scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Hops up and trails behind the blob until it's put down.
func follow(blob: Node2D) -> void:
	blob_to_follow = blob
	# Over the blob, so it's never hidden behind it
	z_index = 1
	remove_from_group("magnets")
	set_deferred("monitoring", false)
	hop()


## Put back on the grass, a little way behind the blob. It can be picked
## up again once the blob has moved off it.
func put_down() -> void:
	if blob_to_follow != null:
		position = blob_to_follow.position + trailing_offset() * 1.6
	blob_to_follow = null
	z_index = 0
	add_to_group("magnets")
	hop()
	await get_tree().create_timer(0.6, false).timeout
	if is_instance_valid(self) and not is_leaving:
		monitoring = true


func trailing_offset() -> Vector2:
	var heading: Vector2 = Vector2.ZERO
	if "velocity" in blob_to_follow:
		heading = blob_to_follow.velocity
	if heading.length() < 20.0:
		return Vector2(-TRAIL_DISTANCE, 30)
	return -heading.normalized() * TRAIL_DISTANCE


func _process(delta: float) -> void:
	bob_time += delta
	if blob_to_follow != null and is_instance_valid(blob_to_follow):
		position = position.lerp(blob_to_follow.position + trailing_offset(), minf(1.0, 10.0 * delta))
	queue_redraw()


func hop() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func wobble() -> void:
	if wobble_tween != null:
		wobble_tween.kill()
	wobble_tween = create_tween()
	for swing in [0.25, -0.2, 0.14, -0.07, 0.0]:
		wobble_tween.tween_property(self, "rotation", swing, 0.07)


func leave() -> void:
	if is_leaving:
		return
	is_leaving = true
	blob_to_follow = null
	remove_from_group("magnets")
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var lift: float = sin(bob_time * 3.0) * 2.0 if blob_to_follow == null else -6.0
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, SQUARE_SIZE * 0.9, Color(0.1, 0.25, 0.05, 0.25))
	draw_set_transform(Vector2(0, lift))
	draw_stack(self, value, Vector2.ZERO, SQUARE_SIZE)
	draw_set_transform(Vector2.ZERO)


## Where each square goes, its centre measured from the bottom middle of
## the stack. A column for now: 1 at the bottom, upwards from there.
static func square_centres(number: int, square_size: float) -> Array[Vector2]:
	var centres: Array[Vector2] = []
	for square_index in number:
		centres.append(Vector2(0, -square_size / 2.0 - square_index * (square_size + SQUARE_GAP)))
	return centres


static func square_colour(number: int, square_index: int) -> Color:
	if number == 7:
		return SEVEN_STRIPES[square_index % SEVEN_STRIPES.size()]
	if number == 9:
		return NINE_GREYS[square_index % NINE_GREYS.size()]
	return NUMBER_COLOURS.get(number, PaintColours.PURPLE)


static func edge_colour(number: int, fill: Color) -> Color:
	if number == 10:
		return PaintColours.RED
	return fill.darkened(0.35)


## The stack standing on bottom_middle, with the number on its bottom square.
static func draw_stack(canvas: CanvasItem, number: int, bottom_middle: Vector2, square_size: float) -> void:
	var centres: Array[Vector2] = square_centres(number, square_size)
	for square_index in centres.size():
		var fill: Color = square_colour(number, square_index)
		var square: Rect2 = Rect2(bottom_middle + centres[square_index] - Vector2.ONE * square_size / 2.0, Vector2.ONE * square_size)
		canvas.draw_rect(square.grow(2.0), edge_colour(number, fill))
		canvas.draw_rect(square, fill)
		canvas.draw_rect(Rect2(square.position + Vector2(3, 3), Vector2(square_size * 0.35, square_size * 0.18)), Color(1, 1, 1, 0.35))
	var font: Font = canvas.get_tree().root.theme.default_font
	var label: String = str(number)
	var font_size: int = int(square_size * (0.85 if label.length() == 1 else 0.7))
	var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline: Vector2 = bottom_middle + centres[0] + Vector2(-width / 2.0, font_size * 0.36)
	canvas.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color.WHITE)
	canvas.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
