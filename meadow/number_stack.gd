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
## How the squares are laid out - see square_centres.
var arrangement: String = "column"
## Off while counting how many are left after taking away.
var shows_number: bool = true
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
	draw_stack(self, value, Vector2.ZERO, SQUARE_SIZE, arrangement, shows_number)
	draw_set_transform(Vector2.ZERO)


## Where each square goes, its centre measured from the bottom middle of
## the stack. "column": one on top of another, up to 10. Past 10 it's a
## white column of ten with the rest beside it. "square" and "rows:3" lay
## the same squares out as a grid, bottom row first.
static func square_centres(number: int, square_size: float, arrangement: String = "column") -> Array[Vector2]:
	var step: float = square_size + SQUARE_GAP
	var centres: Array[Vector2] = []
	var columns: int = 1
	if arrangement == "square":
		columns = maxi(1, int(round(sqrt(number))))
	elif arrangement.begins_with("rows:"):
		columns = maxi(1, ceili(number / float(maxi(1, int(arrangement.trim_prefix("rows:"))))))
	if columns > 1:
		for square_index in number:
			var column: int = square_index % columns
			var row: int = square_index / columns
			centres.append(Vector2((column - (columns - 1) / 2.0) * step, -square_size / 2.0 - row * step))
		return centres
	for square_index in number:
		var column_x: float = 0.0
		var height_in_column: int = square_index
		if number > 10:
			column_x = -step / 2.0 if square_index < 10 else step / 2.0
			height_in_column = square_index if square_index < 10 else square_index - 10
		centres.append(Vector2(column_x, -square_size / 2.0 - height_in_column * step))
	return centres


## The colour of one square. Past 10, the first ten are the white ten and
## the rest take the colour of what's left over.
static func square_colour(number: int, square_index: int) -> Color:
	if number > 10:
		if square_index < 10:
			return NUMBER_COLOURS[10]
		return square_colour(number - 10, square_index - 10)
	if number == 7:
		return SEVEN_STRIPES[square_index % SEVEN_STRIPES.size()]
	if number == 9:
		return NINE_GREYS[square_index % NINE_GREYS.size()]
	return NUMBER_COLOURS.get(number, PaintColours.PURPLE)


static func edge_colour(fill: Color) -> Color:
	if fill == Color.WHITE:
		return PaintColours.RED
	return fill.darkened(0.35)


## The stack standing on bottom_middle, with its number on a tag at the bottom.
static func draw_stack(canvas: CanvasItem, number: int, bottom_middle: Vector2, square_size: float,
		arrangement: String = "column", shows_number: bool = true) -> void:
	var centres: Array[Vector2] = square_centres(number, square_size, arrangement)
	# Rows are each the number in a row - 3 rows of 4 is three 4s
	var row_length: int = 0
	if arrangement.begins_with("rows:"):
		row_length = ceili(number / float(maxi(1, int(arrangement.trim_prefix("rows:")))))
	for square_index in centres.size():
		var fill: Color = square_colour(row_length, square_index % row_length) if row_length > 0 else square_colour(number, square_index)
		var square: Rect2 = Rect2(bottom_middle + centres[square_index] - Vector2.ONE * square_size / 2.0, Vector2.ONE * square_size)
		canvas.draw_rect(square.grow(2.0), edge_colour(fill))
		canvas.draw_rect(square, fill)
		canvas.draw_rect(Rect2(square.position + Vector2(3, 3), Vector2(square_size * 0.35, square_size * 0.18)), Color(1, 1, 1, 0.35))
	if not shows_number:
		return
	var font: Font = canvas.get_tree().root.theme.default_font
	var label: String = str(number)
	var is_one_column: bool = number <= 10 and arrangement == "column"
	var font_size: int = int(square_size * (0.85 if label.length() == 1 else 0.7))
	var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var label_centre: Vector2 = bottom_middle + centres[0] if is_one_column else bottom_middle + Vector2(0, square_size * 0.55)
	if not is_one_column:
		# A white tag under a wide stack, so the number reads as one
		font_size = int(square_size * 0.8)
		width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var tag: Rect2 = Rect2(label_centre - Vector2(width / 2.0 + 8, font_size * 0.55), Vector2(width + 16, font_size * 1.1))
		canvas.draw_rect(tag.grow(2.0), PaintColours.INK)
		canvas.draw_rect(tag, Color.WHITE)
	var baseline: Vector2 = label_centre + Vector2(-width / 2.0, font_size * 0.36)
	canvas.draw_string_outline(canvas.get_tree().root.theme.default_font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color.WHITE)
	canvas.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
