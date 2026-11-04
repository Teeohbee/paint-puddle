class_name PuddleFriend
extends Node2D
## The first time a colour is made, a little puddle of it hops out of the
## blob and says hello: "Hello! I'm Plum. Purple and black made me." Then it
## hops off to the corner and lives in the book. Only one talks at a time -
## a new friend sends the last one off early.

const RADIUS: float = 34.0
## Drawn bigger in the meadow and on paper than in the book, to stand beside the blob.
const SCALE_IN_PLAY: float = 1.5
const SECONDS_TALKING: float = 3.2
const BUBBLE_FONT_SIZE: int = 40
const BUBBLE_SMALL_FONT_SIZE: int = 32

static var friend_talking: PuddleFriend

var paint_name: String = "plum"
var first_line: String = ""
var second_line: String = ""
var wobble_time: float = 0.0
var bubble_shown: float = 0.0
var is_leaving: bool = false


## Hops a new friend out at the given spot (the blob) and starts it talking.
## mixed_from and added are the paints that made it ("purple" + "black"); a
## first dip from clean passes "clean".
static func say_hello(parent: Node, at: Vector2, made_paint: String, mixed_from: String, added: String) -> PuddleFriend:
	if friend_talking != null and is_instance_valid(friend_talking):
		friend_talking.hop_away()
	var friend: PuddleFriend = PuddleFriend.new()
	friend.paint_name = made_paint
	friend.first_line = "Hello! I'm %s." % PaintMixing.friend_name_for(made_paint)
	friend.second_line = how_i_was_made(made_paint, mixed_from, added)
	friend.position = at
	parent.add_child(friend)
	friend_talking = friend
	friend.hop_out()
	return friend


static func how_i_was_made(made_paint: String, mixed_from: String, added: String) -> String:
	if mixed_from == "clean" or mixed_from == made_paint:
		match made_paint:
			"white": return "Dip in me to make colours lighter!"
			"black": return "Dip in me to make colours darker!"
		return "Mix me with other colours!"
	return "%s and %s made me." % [PaintMixing.word_for(mixed_from), PaintMixing.word_for(added).to_lower()]


func hop_out() -> void:
	scale = Vector2.ZERO
	var start: Vector2 = position
	var landing: Vector2 = position + Vector2(130 if position.x < 1500 else -130, -90)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(progress: float): position = start.lerp(landing, progress) - Vector2(0, sin(progress * PI) * 70.0),
		0.0, 1.0, 0.45)
	tween.tween_property(self, "bubble_shown", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(SECONDS_TALKING)
	tween.tween_callback(hop_away)


## Off to the bottom corner, getting smaller, then gone - it lives in the book now.
func hop_away() -> void:
	if is_leaving:
		return
	is_leaving = true
	if friend_talking == self:
		friend_talking = null
	var start: Vector2 = position
	var corner: Vector2 = Vector2(1860, 1040)
	var tween: Tween = create_tween()
	tween.tween_property(self, "bubble_shown", 0.0, 0.15)
	for hop_index in 3:
		var from: Vector2 = start.lerp(corner, hop_index / 3.0)
		var to: Vector2 = start.lerp(corner, (hop_index + 1) / 3.0)
		tween.tween_method(func(progress: float): position = from.lerp(to, progress) - Vector2(0, sin(progress * PI) * 50.0),
			0.0, 1.0, 0.28)
	tween.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 0.3)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	wobble_time += delta
	queue_redraw()


func _draw() -> void:
	draw_friend(self, paint_name, Vector2.ZERO, SCALE_IN_PLAY, wobble_time)
	if bubble_shown > 0.01:
		draw_bubble()


func draw_bubble() -> void:
	var font: Font = get_tree().root.theme.default_font
	var first_width: float = font.get_string_size(first_line, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_FONT_SIZE).x
	var second_width: float = font.get_string_size(second_line, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_SMALL_FONT_SIZE).x
	var bubble_size: Vector2 = Vector2(maxf(first_width, second_width) + 60, 116)
	# Everything is drawn from the tip of the bubble's tail, just above the friend
	# Near the top of the screen the bubble hangs below the friend instead
	var is_below: bool = global_position.y < 260.0
	var tail_tip: Vector2 = Vector2(0, RADIUS * SCALE_IN_PLAY * 0.6 + 8) if is_below else Vector2(0, -RADIUS * SCALE_IN_PLAY * 0.6 - 8)
	draw_set_transform(tail_tip, 0.0, Vector2(1.0, -1.0 if is_below else 1.0) * bubble_shown)
	# Keep the bubble on screen whichever side the friend is on
	var tip_on_screen_x: float = global_position.x
	var bubble_left: float = clampf(-bubble_size.x / 2.0, 30 - tip_on_screen_x, 1890 - tip_on_screen_x - bubble_size.x)
	var bubble_rect: Rect2 = Rect2(Vector2(bubble_left, -24 - bubble_size.y), bubble_size)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.set_corner_radius_all(30)
	box.shadow_color = Color(0, 0, 0, 0.18)
	box.shadow_size = 8
	box.anti_aliasing = true
	box.border_color = PaintMixing.colour_of(paint_name).darkened(0.2)
	box.set_border_width_all(5)
	draw_style_box(box, bubble_rect)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -30), Vector2(14, -30), Vector2(0, 0)]), Color.WHITE)
	if is_below:
		draw_set_transform(tail_tip, 0.0, Vector2.ONE * bubble_shown)
		bubble_rect.position.y = 24
	draw_string(font, bubble_rect.position + Vector2(30, 50), first_line, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_FONT_SIZE, PaintColours.INK)
	draw_string(font, bubble_rect.position + Vector2(30, 94), second_line, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_SMALL_FONT_SIZE,
		PaintColours.INK.lightened(0.2))
	draw_set_transform(Vector2.ZERO)


## A small puddle of paint with a face, used here and in the book. Flatter
## and splashier than the blob, with little droplets, so it's not mistaken
## for the player.
static func draw_friend(canvas: CanvasItem, friend_paint: String, centre: Vector2, size_scale: float, time: float) -> void:
	var colour: Color = PaintMixing.colour_of(friend_paint)
	var radius: float = RADIUS * size_scale
	var rim_colour: Color = colour.darkened(0.3) if colour.get_luminance() < 0.85 else Color(0.7, 0.7, 0.74)
	canvas.draw_colored_polygon(splat_points(centre + Vector2(0, radius * 0.12), radius * 1.05, time, 0.32), Color(0.1, 0.2, 0.05, 0.18))
	canvas.draw_colored_polygon(splat_points(centre, radius + 4 * size_scale, time, 0.62), rim_colour)
	canvas.draw_colored_polygon(splat_points(centre, radius, time, 0.62), colour)
	for droplet_index in 3:
		var angle: float = [0.35, 2.75, 3.35][droplet_index]
		var droplet_centre: Vector2 = centre + Vector2.from_angle(angle) * Vector2(radius * 1.32, radius * 0.86)
		canvas.draw_circle(droplet_centre, (5.0 + droplet_index * 1.5) * size_scale, rim_colour)
		canvas.draw_circle(droplet_centre, (3.5 + droplet_index * 1.5) * size_scale, colour)
	canvas.draw_colored_polygon(ThingDrawings.ellipse_points(centre + Vector2(-radius * 0.45, -radius * 0.28),
		Vector2(radius * 0.22, radius * 0.1), -0.4), Color(1, 1, 1, 0.45))
	var face_lift: float = -radius * 0.08 + sin(time * 2.4) * 1.5 * size_scale
	for side in [-1.0, 1.0]:
		var eye_centre: Vector2 = centre + Vector2(side * radius * 0.3, face_lift - radius * 0.08)
		canvas.draw_circle(eye_centre, radius * 0.17, Color.WHITE)
		canvas.draw_circle(eye_centre + Vector2(0, radius * 0.03), radius * 0.1, PaintColours.INK)
		canvas.draw_circle(eye_centre + Vector2(-radius * 0.03, -radius * 0.02), radius * 0.035, Color.WHITE)
	canvas.draw_arc(centre + Vector2(0, face_lift + radius * 0.12), radius * 0.16, 0.3, PI - 0.3, 10, PaintColours.INK,
		maxf(2.0, 3.0 * size_scale), true)
	canvas.draw_circle(centre + Vector2(-radius * 0.52, face_lift + radius * 0.14), radius * 0.09, Color(1.0, 0.5, 0.55, 0.45))
	canvas.draw_circle(centre + Vector2(radius * 0.52, face_lift + radius * 0.14), radius * 0.09, Color(1.0, 0.5, 0.55, 0.45))


## A flattened, lumpy puddle shape that ripples a little.
static func splat_points(centre: Vector2, radius: float, time: float, flatness: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in 28:
		var angle: float = TAU * point_index / 28.0
		var lumpiness: float = 1.0 + 0.07 * sin(angle * 5.0 + 1.3) + 0.03 * sin(angle * 3.0 + time * 2.0)
		points.append(centre + Vector2(cos(angle), sin(angle) * flatness) * radius * lumpiness)
	return points
