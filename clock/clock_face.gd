class_name ClockFace
extends Node2D
## The home clock face, drawn round this node's position: a white face with
## an ink rim and 60 ink minute marks (the fives bolder), big rainbow
## numbers, two plain ink hands, and a small puddle blob in the middle
## holding them and looking at the hand that matters.
##
## Tell it where to point with wind_to(); the hands sweep there smoothly.
## Times are minutes wound since midnight and aren't wrapped, so a sweep
## across midnight goes forwards, not all the way back round.

const RADIUS: float = 330.0
const RIM_WIDTH: float = 20.0
const NUMBER_FONT_SIZE: int = 70
## How quickly the hands catch up with where they're wound to.
const SWEEP_SPEED: float = 16.0
## Close enough to count as there.
const SETTLED_MINUTES: float = 0.02

var shows_minute_hand: bool = true
## The colour of the puddle blob in the middle.
var blob_colour: Color = PaintColours.RED
## Where the hands are wound to, and where they're drawn on the way there.
var wound_minutes: int = 0
var shown_minutes: float = 0.0


func wind_to(new_wound_minutes: int) -> void:
	wound_minutes = new_wound_minutes


## Straight there, no sweep.
func jump_to(new_wound_minutes: int) -> void:
	wound_minutes = new_wound_minutes
	shown_minutes = new_wound_minutes
	queue_redraw()


func is_sweeping() -> bool:
	return absf(wound_minutes - shown_minutes) > SETTLED_MINUTES


func _process(delta: float) -> void:
	if not is_sweeping():
		return
	var catch_up: float = 1.0 - exp(-delta * SWEEP_SPEED)
	shown_minutes += (wound_minutes - shown_minutes) * catch_up
	if not is_sweeping():
		shown_minutes = wound_minutes
	queue_redraw()


func _draw() -> void:
	draw_face()
	draw_hands()
	draw_puddle_blob()


func draw_face() -> void:
	draw_circle(Vector2(0, 14), RADIUS + RIM_WIDTH, Color(0, 0, 0, 0.12))
	draw_circle(Vector2.ZERO, RADIUS + RIM_WIDTH, PaintColours.INK)
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
	for minute in ClockTime.MINUTES_IN_AN_HOUR:
		var angle: float = angle_of_turns(minute / 60.0)
		var is_a_five: bool = minute % 5 == 0
		var mark_length: float = 28.0 if is_a_five else 13.0
		var mark_width: float = 7.0 if is_a_five else 3.0
		draw_line(point_at(angle, RADIUS - 10 - mark_length), point_at(angle, RADIUS - 10), PaintColours.INK, mark_width)
	var font: Font = game_font()
	for number in range(1, 13):
		var spot: Vector2 = point_at(angle_of_turns(number / 12.0), RADIUS - 90)
		var colour: Color = number_colour(number)
		draw_centred_text(font, str(number), spot + Vector2(3, 3), colour.darkened(0.45))
		draw_centred_text(font, str(number), spot, colour.darkened(0.15))


func draw_hands() -> void:
	draw_hand(angle_of_turns(ClockTime.hour_hand_turns(shown_minutes)), RADIUS * 0.5, 28.0)
	if shows_minute_hand:
		draw_hand(angle_of_turns(ClockTime.minute_hand_turns(shown_minutes)), RADIUS * 0.8, 15.0)


## A rounded ink hand with a short tail behind the middle.
func draw_hand(angle: float, length: float, width: float) -> void:
	var tip: Vector2 = point_at(angle, length)
	var tail: Vector2 = point_at(angle + PI, length * 0.12)
	draw_line(tail, tip, PaintColours.INK, width)
	draw_circle(tip, width / 2.0, PaintColours.INK)
	draw_circle(tail, width / 2.0, PaintColours.INK)


## The blob in the middle holds the hands and watches the minute hand, or the
## hour hand when it's the only one.
func draw_puddle_blob() -> void:
	var watched_turns: float = ClockTime.hour_hand_turns(shown_minutes)
	if shows_minute_hand:
		watched_turns = ClockTime.minute_hand_turns(shown_minutes)
	var looking: Vector2 = Vector2.from_angle(angle_of_turns(watched_turns))
	draw_colored_polygon(wobbly_circle(48.0), blob_colour.darkened(0.35))
	draw_colored_polygon(wobbly_circle(43.0), blob_colour)
	draw_circle(Vector2(-17, -19), 7, Color(1, 1, 1, 0.55))
	for eye_side in [-1, 1]:
		var eye: Vector2 = Vector2(eye_side * 14, -6)
		draw_circle(eye, 11, Color.WHITE)
		draw_circle(eye + looking * 4, 6, PaintColours.INK)
	draw_arc(Vector2(0, 12), 10, 0.3, PI - 0.3, 12, PaintColours.INK, 3.0)


## The game's chunky font, or Godot's own when there's no theme (in a bare test).
func game_font() -> Font:
	if get_tree().root.theme == null:
		return ThemeDB.fallback_font
	return get_tree().root.theme.default_font


## The numbers go round the rainbow, red at 12.
static func number_colour(number: int) -> Color:
	return Color.from_hsv(fposmod(number / 12.0 - 0.02, 1.0), 0.6, 1.0)


## Turns from the 12, clockwise, as an angle Godot can draw with.
static func angle_of_turns(turns: float) -> float:
	return TAU * turns - PI / 2.0


static func point_at(angle: float, distance: float) -> Vector2:
	return Vector2.from_angle(angle) * distance


func draw_centred_text(font: Font, text: String, centre: Vector2, colour: Color) -> void:
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE)
	draw_string(font, centre + Vector2(-text_size.x / 2.0, NUMBER_FONT_SIZE * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, colour)


func wobbly_circle(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 32:
		var angle: float = TAU * index / 32.0
		var wobble: float = 0.06 * sin(3.0 * angle + 2.0) + 0.04 * sin(5.0 * angle - 3.4)
		points.append(Vector2.from_angle(angle) * radius * (1.0 + wobble))
	return points
