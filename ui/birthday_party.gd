class_name BirthdayParty
extends Node2D
## The party behind the title on a birthday: bunting along the top and
## balloons floating up either side of the tiles. On the day itself there are
## lots of balloons with the new age on them; in the birthday week, just the
## odd one. Drawn behind the logo and the tiles. See Birthday.

const BALLOON_RADIUS: Vector2 = Vector2(46, 56)
const BALLOON_RISE_SPEED: float = 140.0
## Balloons stay out of the middle, where the logo and tiles are.
const BALLOON_LANES: Array[Vector2] = [Vector2(70, 350), Vector2(1570, 1850)]
const SECONDS_BETWEEN_BALLOONS_ON_THE_DAY: float = 0.8
const SECONDS_BETWEEN_BALLOONS_IN_THE_WEEK: float = 5.0
const BUNTING_FLAG_COUNT: int = 25
const BUNTING_SAGS: int = 3

var party: Birthday.Party
## Printed on each balloon on the day itself; empty in the week.
var balloon_number: String = ""
var balloons: Array[Dictionary] = []
var seconds_until_next_balloon: float = 0.0
var age: float = 0.0
var font: Font


func _init(party_to_throw: Birthday.Party, new_age: int) -> void:
	party = party_to_throw
	if party == Birthday.Party.BIRTHDAY:
		balloon_number = str(new_age)


func _ready() -> void:
	font = get_tree().root.theme.default_font if get_tree().root.theme != null else ThemeDB.fallback_font
	# The day starts with the sky already full of balloons; the week with one on its way
	var starting_balloons: int = 8 if party == Birthday.Party.BIRTHDAY else 1
	for balloon_index in starting_balloons:
		add_balloon(randf_range(200, 1150))
	seconds_until_next_balloon = seconds_between_balloons()


func seconds_between_balloons() -> float:
	if party == Birthday.Party.BIRTHDAY:
		return SECONDS_BETWEEN_BALLOONS_ON_THE_DAY
	return SECONDS_BETWEEN_BALLOONS_IN_THE_WEEK


func add_balloon(start_height: float) -> void:
	var lane: Vector2 = BALLOON_LANES.pick_random()
	balloons.append({
		"position": Vector2(randf_range(lane.x, lane.y), start_height),
		"colour": PaintColours.RAINBOW.pick_random(),
		"sway_offset": randf_range(0, TAU),
		"speed": BALLOON_RISE_SPEED * randf_range(0.8, 1.2),
	})


func _process(delta: float) -> void:
	age += delta
	seconds_until_next_balloon -= delta
	if seconds_until_next_balloon <= 0.0:
		add_balloon(1080 + BALLOON_RADIUS.y + 10)
		seconds_until_next_balloon = seconds_between_balloons()
	for balloon in balloons:
		balloon.position.y -= balloon.speed * delta
	# Gone off the top, string and all
	balloons = balloons.filter(func(balloon): return balloon.position.y > -BALLOON_RADIUS.y - 200)
	queue_redraw()


func _draw() -> void:
	for balloon in balloons:
		draw_balloon(balloon)
	draw_bunting()


func draw_balloon(balloon: Dictionary) -> void:
	var sway: float = sin(age * 1.4 + balloon.sway_offset)
	var centre: Vector2 = balloon.position + Vector2(sway * 14.0, 0)
	var tilt: float = sway * 0.08
	var colour: Color = balloon.colour
	var knot: Vector2 = centre + Vector2(0, BALLOON_RADIUS.y).rotated(tilt)
	var string_points: PackedVector2Array = PackedVector2Array()
	for point_index in 9:
		var along: float = point_index / 8.0
		string_points.append(knot + Vector2(sin(along * TAU + age * 2.0 + balloon.sway_offset) * 8.0 * along, along * 170.0))
	draw_polyline(string_points, PaintColours.INK.lerp(Color.WHITE, 0.3), 2.5, true)
	draw_set_transform(centre, tilt, Vector2.ONE)
	draw_colored_polygon(oval_points(BALLOON_RADIUS + Vector2(4, 4)), colour.darkened(0.35))
	draw_colored_polygon(oval_points(BALLOON_RADIUS), colour)
	draw_colored_polygon(PackedVector2Array([Vector2(0, BALLOON_RADIUS.y - 4), Vector2(-9, BALLOON_RADIUS.y + 10), Vector2(9, BALLOON_RADIUS.y + 10)]), colour.darkened(0.35))
	draw_set_transform(centre + Vector2(-16, -22).rotated(tilt), tilt - 0.5, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.5))
	if not balloon_number.is_empty():
		var number_size: int = 64
		var number_width: float = font.get_string_size(balloon_number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
		draw_set_transform(centre, tilt, Vector2.ONE)
		var baseline: Vector2 = Vector2(-number_width / 2.0, number_size * 0.35)
		draw_string_outline(font, baseline, balloon_number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, 10, colour.darkened(0.35))
		draw_string(font, baseline, balloon_number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func oval_points(radius: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in 32:
		var angle: float = TAU * point_index / 32
		# A touch narrower at the bottom, like a real balloon
		var narrowing: float = 1.0 - 0.12 * maxf(sin(angle), 0.0)
		points.append(Vector2(cos(angle) * radius.x * narrowing, sin(angle) * radius.y))
	return points


## A string across the top in a few gentle sags, with rainbow flags hanging off it.
func draw_bunting() -> void:
	var string_points: PackedVector2Array = PackedVector2Array()
	for point_index in 97:
		string_points.append(bunting_point(point_index / 96.0))
	draw_polyline(string_points, PaintColours.INK, 3.0, true)
	for flag_index in BUNTING_FLAG_COUNT:
		var along: float = (flag_index + 0.5) / BUNTING_FLAG_COUNT
		var left: Vector2 = bunting_point(along - 0.4 / BUNTING_FLAG_COUNT)
		var right: Vector2 = bunting_point(along + 0.4 / BUNTING_FLAG_COUNT)
		var swing: float = sin(age * 2.0 + flag_index * 0.9) * 5.0
		var tip: Vector2 = (left + right) / 2.0 + Vector2(swing, 50)
		var flag: PackedVector2Array = PackedVector2Array([left, right, tip])
		draw_colored_polygon(flag, PaintColours.RAINBOW[flag_index % PaintColours.RAINBOW.size()])
		flag.append(left)
		draw_polyline(flag, PaintColours.INK, 2.5, true)


func bunting_point(along: float) -> Vector2:
	var sag: float = absf(sin(along * PI * BUNTING_SAGS)) * 34.0
	return Vector2(-20 + along * 1960, 6 + sag)
