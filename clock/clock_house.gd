class_name ClockHouse
extends Node2D
## The blob household's busy cutaway doll's house beside the clock: four
## furnished rooms (bedroom and bathroom upstairs, kitchen and living room
## downstairs), a tiled roof with a chimney, a side garden, and big sky all
## round. Ported from the prototype on prototype/house-look (variant B).
##
## The sky, sun and moon, stars and the lights follow the hands live
## (live_minutes, set every frame). The moment only changes when a time is
## confirmed (show_moment), so a set card can't be solved by watching them.
## The blobs act the moment out only while the hands show its time; while
## the hands are away they rest by the sky (asleep in the dark, on the sofa
## by day), so the house never shows the wrong part of the day and gives
## nothing away the sky doesn't. The moment's room gets a faint warm outline
## and the others dim a little, only while it's acted out.
##
## Everything is drawn in the prototype's own space (PANEL below), and the
## node's position and scale fit it to the space it's given.

## The panel in the space the house is drawn in.
const PANEL: Rect2 = Rect2(980, 190, 880, 840)
## Every room is drawn in its own 800 x 760 space, then scaled into place.
const ROOM: Vector2 = Vector2(800, 760)
const FLOOR_Y: float = 600.0

const INK: Color = PaintColours.INK
const CREAM: Color = PaintColours.CREAM
const RED: Color = PaintColours.RED
const BLUE: Color = PaintColours.BLUE
const YELLOW: Color = PaintColours.YELLOW
const GREEN: Color = Color(0.45, 0.8, 0.4)
const WOOD: Color = Color(0.72, 0.5, 0.32)
const WHITE: Color = Color(1.0, 1.0, 1.0)

const SKY_KEYS: Array = [
	[0, Color(0.1, 0.12, 0.3)], [300, Color(0.12, 0.14, 0.34)], [390, Color(1.0, 0.7, 0.62)],
	[480, Color(0.62, 0.84, 1.0)], [1020, Color(0.6, 0.82, 1.0)], [1140, Color(1.0, 0.62, 0.45)],
	[1230, Color(0.3, 0.22, 0.48)], [1320, Color(0.1, 0.12, 0.3)], [1440, Color(0.1, 0.12, 0.3)],
]
## The moment's room glows warm and the rest dim this much.
const OTHER_ROOMS_DIMMED: float = 0.1
const MOMENT_ROOM_OUTLINE: Color = Color(1.0, 0.8, 0.35, 0.85)

## The time the hands show right now, as they sweep. Drives the sky and lights.
var live_minutes_of_the_day: float = 7 * 60
## The moment the blobs are doing: the last time confirmed.
var moment: Dictionary = {}
## The time that moment was confirmed at. The blobs act it out only while the hands show it.
var moment_minutes_of_the_day: int = 7 * 60
## The little blob is the player's own, in the colour it is in the Meadow and Hills.
var player_blob_colour: Color = PaintMixing.colour_of("clean")
var time: float = 0.0
var font: Font
var room_transform: Transform2D = Transform2D.IDENTITY


func _ready() -> void:
	font = ThemeDB.fallback_font if get_tree().root.theme == null else get_tree().root.theme.default_font
	if moment.is_empty():
		show_moment(int(live_minutes_of_the_day))


## Fits the house into a box on screen, as big as it goes without stretching.
func fit_into(box: Rect2) -> void:
	var fitting_scale: float = minf(box.size.x / PANEL.size.x, box.size.y / PANEL.size.y)
	scale = Vector2(fitting_scale, fitting_scale)
	var drawn_size: Vector2 = PANEL.size * fitting_scale
	position = box.position + (box.size - drawn_size) / 2.0 - PANEL.position * fitting_scale


## The blobs go and do what happens at this time.
func show_moment(minutes_of_the_day: int) -> void:
	moment = DayMoments.moment_at(minutes_of_the_day)
	moment_minutes_of_the_day = posmod(minutes_of_the_day, ClockTime.MINUTES_IN_A_DAY)
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	draw_dolls_house()


func live_minutes() -> float:
	return fposmod(live_minutes_of_the_day, ClockTime.MINUTES_IN_A_DAY)


## Closer than this and the hands count as showing the moment's time. Under
## a minute, so rung 8's single minutes still count as away.
const SAME_TIME_MINUTES: float = 0.5
## What the blobs do while the hands are away from the moment's time.
const RESTING_IN_THE_DARK: Dictionary = {"room": "bedroom", "doing": "asleep"}
const RESTING_BY_DAY: Dictionary = {"room": "living", "doing": "sofa"}
## Darker than this and the blobs rest in bed.
const DARK_ENOUGH_FOR_BED: float = 0.2


func hands_show_the_moment() -> bool:
	var apart: float = absf(live_minutes() - moment_minutes_of_the_day)
	return minf(apart, ClockTime.MINUTES_IN_A_DAY - apart) < SAME_TIME_MINUTES


## The moment while the hands show its time, otherwise resting by the sky.
func acted_out_moment() -> Dictionary:
	if hands_show_the_moment():
		return moment
	if darkness() > DARK_ENOUGH_FOR_BED:
		return RESTING_IN_THE_DARK
	return RESTING_BY_DAY


## The room with the warm outline, or "" while the blobs are resting.
func highlighted_room() -> String:
	if not hands_show_the_moment():
		return ""
	return moment_room()


func doing() -> String:
	return acted_out_moment().get("doing", "asleep")


func visitor() -> String:
	return acted_out_moment().get("visitor", "")


func moment_room() -> String:
	return acted_out_moment().get("room", "bedroom")


# ---------------------------------------------------------------- room space

func begin_room(rect: Rect2) -> void:
	room_transform = Transform2D(0.0, rect.size / ROOM, 0.0, rect.position)
	draw_set_transform_matrix(room_transform)


func place(at: Vector2, scale_by: float = 1.0, turn: float = 0.0) -> void:
	draw_set_transform_matrix(room_transform * Transform2D(turn, Vector2(scale_by, scale_by), 0.0, at))


func back_to_room() -> void:
	draw_set_transform_matrix(room_transform)


func end_room() -> void:
	room_transform = Transform2D.IDENTITY
	draw_set_transform_matrix(Transform2D.IDENTITY)


func thing(name: String, at: Vector2, scale_by: float, flip: bool = false) -> void:
	draw_set_transform_matrix(room_transform * Transform2D(0.0, Vector2(-scale_by if flip else scale_by, scale_by), 0.0, at))
	ThingDrawings.draw(self, name)
	back_to_room()


# ---------------------------------------------------------------- sky and light

func sky_colour(minutes: float) -> Color:
	for index in SKY_KEYS.size() - 1:
		var from: Array = SKY_KEYS[index]
		var to: Array = SKY_KEYS[index + 1]
		if minutes >= from[0] and minutes <= to[0]:
			return (from[1] as Color).lerp(to[1], (minutes - from[0]) / float(to[0] - from[0]))
	return SKY_KEYS[0][1]


func darkness() -> float:
	return clampf(1.0 - sky_colour(live_minutes()).get_luminance() * 1.4, 0.0, 0.7)


func outdoor(colour: Color) -> Color:
	return colour.darkened(darkness() * 0.65)


func draw_sky(rect: Rect2) -> void:
	var minutes := live_minutes()
	var sky := sky_colour(minutes)
	draw_rect(rect, sky)
	draw_rect(Rect2(rect.position.x, rect.get_center().y, rect.size.x, rect.size.y / 2.0), Color(1, 1, 1, 0.08))
	var dark := darkness()
	if dark > 0.3:
		var star_count := int(rect.get_area() / 9000.0) + 3
		for index in star_count:
			var star := rect.position + Vector2(fposmod(sin(index * 12.9898) * 43758.5, rect.size.x - 16) + 8, fposmod(sin(index * 78.233) * 24634.6, rect.size.y * 0.7) + 8)
			var twinkle := 0.6 + 0.4 * sin(time * 2.0 + index)
			draw_circle(star, 2.5 + rect.size.x / 400.0, Color(1, 1, 0.85, (dark - 0.3) * 2.2 * twinkle))
	var radius := minf(rect.size.x, rect.size.y) * 0.11
	var is_day := minutes >= 360 and minutes < 1080
	var progress := fposmod(minutes - 360.0, 720.0) / 720.0
	var body := Vector2(lerpf(rect.position.x + radius * 1.6, rect.end.x - radius * 1.6, progress),
		rect.end.y - radius * 1.3 - sin(progress * PI) * (rect.size.y - radius * 3.0))
	if is_day:
		for ring in 3:
			draw_circle(body, radius * (1.25 + ring * 0.25), Color(1.0, 0.9, 0.4, 0.12))
		draw_circle(body, radius, Color(1.0, 0.85, 0.25))
		for cloud in 2:
			var drift := fposmod(time * 12.0 + cloud * rect.size.x * 0.55, rect.size.x + radius * 4) - radius * 2
			var at := Vector2(rect.position.x + drift, rect.position.y + rect.size.y * (0.22 + cloud * 0.2))
			for puff in 3:
				clipped_circle(at + Vector2((puff - 1) * radius * 0.8, -radius * 0.2 * float(puff == 1)), radius * (0.6 + 0.25 * float(puff == 1)), Color(1, 1, 1, 0.85), rect)
	else:
		for ring in 2:
			draw_circle(body, radius * (1.2 + ring * 0.25), Color(1.0, 1.0, 0.85, 0.08))
		draw_circle(body, radius * 0.9, Color(0.97, 0.95, 0.82))
		draw_circle(body + Vector2(radius * 0.38, -radius * 0.22), radius * 0.75, sky)


## Night visitors that show wherever there's sky or garden.
func draw_sky_visitors(rect: Rect2) -> void:
	if visitor() == "shooting stars":
		var progress := fposmod(time * 0.5, 1.0)
		var head := rect.position + rect.size * Vector2(0.2 + progress * 0.6, 0.15 + progress * 0.3)
		draw_line(head - rect.size * Vector2(0.18, 0.09), head, Color(1, 1, 0.9, 0.7 * (1.0 - progress)), maxf(3.0, rect.size.x / 120.0))
		draw_circle(head, maxf(4.0, rect.size.x / 80.0), Color(1, 1, 0.9, 1.0 - progress))
	if visitor() == "birds":
		for bird in 3:
			var at := rect.position + rect.size * Vector2(0.25 + bird * 0.18 + fposmod(time * 0.05, 0.3), 0.3 + 0.08 * sin(bird * 2.0))
			var flap := 0.3 * sin(time * 8.0 + bird)
			var span := rect.size.x / 30.0
			draw_line(at, at + Vector2(-span, -span * (0.5 + flap)), INK, maxf(2.0, span / 5.0))
			draw_line(at, at + Vector2(span, -span * (0.5 + flap)), INK, maxf(2.0, span / 5.0))


## A circle cut to a box, so glows and clouds never spill out of their room.
func clipped_circle(centre: Vector2, radius: float, colour: Color, box: Rect2) -> void:
	draw_clamped(ThingDrawings.ellipse_points(centre, Vector2(radius, radius), 0.0, 48), colour, box)


## Clamps a convex shape into the box. Skips it when nothing is left inside
## (a shape fully outside clamps flat onto the edge and can't be drawn).
func draw_clamped(points: PackedVector2Array, colour: Color, box: Rect2) -> void:
	var kept := PackedVector2Array()
	for point in points:
		var clamped := point.clamp(box.position, box.end)
		if kept.is_empty() or not kept[kept.size() - 1].is_equal_approx(clamped):
			kept.append(clamped)
	if kept.size() > 1 and kept[0].is_equal_approx(kept[kept.size() - 1]):
		kept.remove_at(kept.size() - 1)
	if kept.size() < 3:
		return
	var twice_area := 0.0
	for index in kept.size():
		var next := kept[(index + 1) % kept.size()]
		twice_area += kept[index].x * next.y - next.x * kept[index].y
	if absf(twice_area) < 2.0:
		return
	draw_colored_polygon(kept, colour)


func clipped_ellipse(centre: Vector2, radii: Vector2, colour: Color, box: Rect2) -> void:
	draw_clamped(ThingDrawings.ellipse_points(centre, radii, 0.0, 48), colour, box)


func night_shade(lights: Array) -> void:
	var dark := darkness()
	if dark > 0.02:
		draw_rect(Rect2(Vector2.ZERO, ROOM), Color(0.06, 0.07, 0.22, dark * 0.8))
	for light in lights:
		var at: Vector2 = light[0]
		var reach: float = light[1]
		for ring in 5:
			clipped_circle(at, reach * (1.0 - ring * 0.17), Color(1.0, 0.85, 0.5, 0.06 + dark * 0.04), Rect2(Vector2.ZERO, ROOM))


# ---------------------------------------------------------------- blobs

func blob(at: Vector2, radius: float, colour: Color, eyes: String = "open", phase: float = 0.0, look: Vector2 = Vector2.ZERO) -> void:
	var body := PackedVector2Array()
	var rim := PackedVector2Array()
	for index in 36:
		var angle := TAU * index / 36.0
		var wobble := 0.035 * sin(3.0 * angle + time * 3.1 + phase) + 0.025 * sin(5.0 * angle - time * 2.3 + phase)
		var direction := Vector2(cos(angle), sin(angle) * 0.94)
		body.append(at + direction * radius * (1.0 + wobble))
		rim.append(at + direction * (radius + 5.0) * (1.0 + wobble))
	draw_colored_polygon(rim, colour.darkened(0.35))
	draw_colored_polygon(body, colour)
	draw_circle(at + Vector2(-radius * 0.42, -radius * 0.45), radius * 0.17, Color(1, 1, 1, 0.45))
	var size := radius / 44.0
	for side in [-1.0, 1.0]:
		var eye: Vector2 = at + Vector2(side * 15.0 * size, -6.0 * size) + look * 5.0 * size
		match eyes:
			"closed":
				draw_arc(eye + Vector2(0, -4 * size), 8.0 * size, 0.5, PI - 0.5, 10, INK, 3.0 * size)
			"happy":
				draw_arc(eye + Vector2(0, 5 * size), 8.0 * size, PI + 0.5, TAU - 0.5, 10, INK, 3.0 * size)
			_:
				draw_circle(eye, 11.0 * size, WHITE)
				draw_circle(eye + look * 3.5 * size, 6.0 * size, INK)
				draw_circle(eye + look * 3.5 * size + Vector2(-2, -2) * size, 2.0 * size, WHITE)
	var mouth := at + Vector2(0, 10 * size) + look * 5.0 * size
	if eyes == "closed":
		draw_circle(mouth, 3.5 * size, INK)
	else:
		draw_arc(mouth, 7.0 * size, 0.35, PI - 0.35, 12, INK, 3.0 * size)


const BIG := 76.0
const MIDDLE := 62.0
const LITTLE := 46.0


func snore(at: Vector2, phase: float) -> void:
	for index in 3:
		var progress := fposmod(time * 0.4 + phase + index / 3.0, 1.0)
		var size := int(22 + progress * 18)
		draw_string(font, at + Vector2(progress * 40, -progress * 90), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(INK, 0.8 * (1.0 - progress)))


func bounce(phase: float, height: float) -> float:
	return -absf(sin(time * 4.0 + phase)) * height


# ---------------------------------------------------------------- room parts

func outlined_rect(rect: Rect2, colour: Color, outline: float = 5.0) -> void:
	draw_rect(rect.grow(outline), colour.darkened(0.45))
	draw_rect(rect, colour)


func wall(colour: Color, pattern: String) -> void:
	draw_rect(Rect2(0, 0, ROOM.x, FLOOR_Y), colour)
	var mark := colour.darkened(0.07)
	match pattern:
		"dots":
			for row in 11:
				for column in 15:
					var dot := Vector2(30 + column * 55 + (row % 2) * 27, 28 + row * 55)
					if dot.x < ROOM.x - 10:
						draw_circle(dot, 6, mark)
		"stripes":
			for column in 12:
				if column * 70 + 30 <= ROOM.x:
					draw_rect(Rect2(column * 70, 0, 30, FLOOR_Y), mark)
		"tiles":
			for row in 11:
				draw_line(Vector2(0, row * 56), Vector2(ROOM.x, row * 56), mark, 3)
			for column in 15:
				draw_line(Vector2(column * 56, 0), Vector2(column * 56, FLOOR_Y), mark, 3)
		"stars":
			for row in 9:
				for column in 12:
					var at := Vector2(40 + column * 68 + (row % 2) * 34, 34 + row * 66)
					if at.x > ROOM.x - 12:
						continue
					draw_line(at - Vector2(9, 0), at + Vector2(9, 0), mark, 4)
					draw_line(at - Vector2(0, 9), at + Vector2(0, 9), mark, 4)
	draw_rect(Rect2(0, FLOOR_Y - 26, ROOM.x, 26), colour.lightened(0.5))
	draw_line(Vector2(0, FLOOR_Y - 26), Vector2(ROOM.x, FLOOR_Y - 26), colour.darkened(0.25), 3)


func wooden_floor(colour: Color) -> void:
	draw_rect(Rect2(0, FLOOR_Y, ROOM.x, ROOM.y - FLOOR_Y), colour)
	for row in 4:
		var y := FLOOR_Y + 8 + row * 34.0
		draw_line(Vector2(0, y), Vector2(ROOM.x, y), colour.darkened(0.12), 3)
		for joint in 4:
			var x := fposmod(joint * 230.0 + row * 117.0, ROOM.x)
			draw_line(Vector2(x, y), Vector2(x, y + 34), colour.darkened(0.12), 3)


func rug(centre: Vector2, radii: Vector2, colour: Color) -> void:
	draw_colored_polygon(ThingDrawings.ellipse_points(centre, radii + Vector2(6, 6)), colour.darkened(0.3))
	draw_colored_polygon(ThingDrawings.ellipse_points(centre, radii), colour)
	draw_colored_polygon(ThingDrawings.ellipse_points(centre, radii * 0.7), colour.lightened(0.25))
	draw_colored_polygon(ThingDrawings.ellipse_points(centre, radii * 0.4), colour)


func window(rect: Rect2, curtain: Color) -> void:
	draw_rect(rect.grow(16), INK)
	draw_rect(rect.grow(10), WHITE)
	draw_sky(rect)
	draw_sky_visitors(rect)
	if visitor() == "owl":
		thing("owl", Vector2(rect.end.x - rect.size.x * 0.28, rect.end.y - rect.size.y * 0.3), rect.size.x / 380.0)
	draw_line(Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y), WHITE, 10)
	draw_line(Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), WHITE, 10)
	draw_rect(Rect2(rect.position.x - 26, rect.end.y + 10, rect.size.x + 52, 18), WHITE.darkened(0.08))
	for side in [0, 1]:
		var x: float = rect.position.x - 34 if side == 0 else rect.end.x + 34
		var inward: float = 1.0 if side == 0 else -1.0
		var curtain_points := PackedVector2Array([
			Vector2(x, rect.position.y - 30), Vector2(x + inward * 70, rect.position.y - 30),
			Vector2(x + inward * 40, rect.get_center().y), Vector2(x + inward * 56, rect.end.y + 40),
			Vector2(x, rect.end.y + 40)])
		draw_colored_polygon(curtain_points, curtain)
		draw_polyline(curtain_points, curtain.darkened(0.35), 4)
		for fold in 2:
			draw_line(Vector2(x + inward * (18 + fold * 18), rect.position.y - 20), Vector2(x + inward * (16 + fold * 14), rect.end.y + 30), curtain.darkened(0.15), 3)
	draw_rect(Rect2(rect.position.x - 50, rect.position.y - 40, rect.size.x + 100, 12), WOOD)


func picture_frame(rect: Rect2, painting: Color) -> void:
	outlined_rect(rect, Color(0.95, 0.75, 0.35), 6)
	draw_rect(rect.grow(-12), CREAM)
	draw_colored_polygon(ThingDrawings.ellipse_points(rect.get_center() + Vector2(0, 8), rect.size * Vector2(0.25, 0.2)), painting)
	draw_circle(rect.get_center() + Vector2(rect.size.x * 0.22, -rect.size.y * 0.18), rect.size.y * 0.1, YELLOW)


func pendant_lamp(x: float, lit: bool) -> void:
	draw_line(Vector2(x, 0), Vector2(x, 60), INK, 4)
	var shade := PackedVector2Array([Vector2(x - 20, 60), Vector2(x + 20, 60), Vector2(x + 46, 104), Vector2(x - 46, 104)])
	draw_colored_polygon(shade, Color(1.0, 0.6, 0.35))
	draw_polyline(shade + PackedVector2Array([shade[0]]), Color(1.0, 0.6, 0.35).darkened(0.4), 4)
	draw_circle(Vector2(x, 108), 12, Color(1.0, 0.95, 0.7) if lit else Color(0.85, 0.85, 0.8))


# ---------------------------------------------------------------- rooms

func draw_room(room_name: String, occupied: bool) -> void:
	match room_name:
		"bedroom": draw_bedroom(occupied)
		"kitchen": draw_kitchen(occupied)
		"living": draw_living_room(occupied)
		"bathroom": draw_bathroom(occupied)
		"garden": draw_garden_room(occupied)


func lamp_is_on(occupied: bool) -> bool:
	return occupied and not is_a_night_doing(doing())


## What happens in the dark: sleeping, and the little one up in the night.
## No lamps go on for these, so the house stays dark.
static func is_a_night_doing(doing_name: String) -> bool:
	return doing_name == "asleep" or doing_name == "drink" or doing_name == "sleepwalk"


func bed_back(x: float, width: float, colour: Color) -> void:
	var headboard := Rect2(x, 470, width, 190)
	ThingDrawings.rounded_box(self, headboard, 30, colour)
	draw_circle(Vector2(x + width / 2.0, 500), 14, colour.lightened(0.3))
	draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(x + width / 2.0, 540), Vector2(width * 0.34, 26)), WHITE.darkened(0.04))


func bed_front(x: float, width: float, blanket: Color, folded: bool) -> void:
	var top := 610.0 if folded else 556.0
	var cover := Rect2(x - 12, top, width + 24, 662 - top)
	ThingDrawings.rounded_box(self, cover, 16, blanket)
	for dot in int(width / 40.0):
		draw_circle(Vector2(x + 20 + dot * 40, top + (662 - top) * 0.6), 7, blanket.lightened(0.35))
	draw_rect(Rect2(x - 12, top, width + 24, 16), WHITE.darkened(0.05))
	for leg_x in [x, x + width - 18]:
		draw_rect(Rect2(leg_x, 662, 18, 34), WOOD.darkened(0.2))


func draw_bedroom(occupied: bool) -> void:
	var doing: String = doing()
	# At night the beds are full even when the moment is elsewhere (the fox at
	# the bins); when the little one is up, the other two are still asleep
	var little_one_is_up: bool = doing == "drink" or doing == "sleepwalk"
	var asleep: bool = doing == "asleep" or little_one_is_up
	wall(Color(0.86, 0.82, 0.98), "stars")
	wooden_floor(Color(0.85, 0.68, 0.5))
	window(Rect2(310, 110, 180, 150), Color(1.0, 0.62, 0.7))
	picture_frame(Rect2(70, 150, 130, 100), BLUE)
	picture_frame(Rect2(610, 170, 110, 90), GREEN)
	rug(Vector2(400, 710), Vector2(320, 40), Color(0.4, 0.75, 0.75))
	pendant_lamp(400, lamp_is_on(occupied))
	# toy box
	ThingDrawings.rounded_box(self, Rect2(560, 690, 110, 56), 8, RED.lightened(0.15))
	thing("ball", Vector2(700, 712), 0.35)
	var folded := occupied and doing != "asleep" and doing != "story" and doing != "bad dream"
	bed_back(40, 250, Color(0.55, 0.65, 1.0))
	bed_back(335, 190, Color(1.0, 0.6, 0.65))
	bed_back(580, 170, Color(1.0, 0.85, 0.45))
	if asleep:
		blob(Vector2(165, 545), BIG, BLUE, "closed", 0.0)
		blob(Vector2(430, 555), MIDDLE, RED, "closed", 1.3)
		if not little_one_is_up:
			blob(Vector2(665, 565), LITTLE, player_blob_colour, "closed", 2.6)
	elif occupied:
		match doing:
			"bad dream":
				blob(Vector2(165, 535), BIG, BLUE, "open", 0.0, Vector2(1, 0.2))
				blob(Vector2(430, 555), MIDDLE, RED, "closed", 1.3)
				blob(Vector2(640, 545), LITTLE, player_blob_colour, "open", 2.6, Vector2(-1, -0.2))
				draw_arc(Vector2(700, 470), 26, PI * 0.9, PI * 2.4, 16, Color(INK, 0.6), 4)
			"asleep":
				blob(Vector2(165, 545), BIG, BLUE, "closed", 0.0)
				blob(Vector2(430, 555), MIDDLE, RED, "closed", 1.3)
				blob(Vector2(665, 565), LITTLE, player_blob_colour, "closed", 2.6)
			"wake":
				blob(Vector2(165, 520 + bounce(0.0, 50)), BIG, BLUE, "happy", 0.0)
				blob(Vector2(430, 530 + bounce(1.1, 60)), MIDDLE, RED, "happy", 1.3)
				blob(Vector2(665, 545 + bounce(2.2, 70)), LITTLE, player_blob_colour, "happy", 2.6)
			"story":
				blob(Vector2(165, 530), BIG, BLUE, "open", 0.0, Vector2(0.6, 0.6))
				blob(Vector2(430, 548), MIDDLE, RED, "open", 1.3, Vector2(-1, 0.1))
				blob(Vector2(665, 560), LITTLE, player_blob_colour, "open", 2.6, Vector2(-1, 0.1))
	bed_front(40, 250, Color(0.4, 0.5, 0.95), folded and doing != "story")
	bed_front(335, 190, Color(0.95, 0.4, 0.5), folded)
	bed_front(580, 170, Color(1.0, 0.72, 0.25), folded)
	if occupied and doing == "story":
		# the open book on the big blob's lap
		var book := PackedVector2Array([Vector2(170, 560), Vector2(250, 540), Vector2(250, 610), Vector2(170, 630), Vector2(90, 610), Vector2(90, 540)])
		draw_colored_polygon(book, WHITE)
		draw_polyline(book + PackedVector2Array([book[0]]), INK, 4)
		draw_line(Vector2(170, 560), Vector2(170, 630), INK, 3)
		thing("cat", Vector2(212, 588), 0.22)
		draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(128, 585), Vector2(16, 12)), RED)
	var lights: Array = []
	if lamp_is_on(occupied):
		lights.append([Vector2(400, 108), 380.0])
	if asleep or doing == "bad dream":
		lights.append([Vector2(740, 560), 70.0])  # night light
	night_shade(lights)
	if asleep:
		snore(Vector2(210, 470), 0.0)
		snore(Vector2(470, 490), 0.33)
		if not little_one_is_up:
			snore(Vector2(690, 515), 0.66)
	var night_light_on: bool = asleep or doing == "bad dream"
	draw_circle(Vector2(740, 560), 12, Color(1.0, 0.9, 0.5) if night_light_on else Color(0.9, 0.9, 0.85))


func draw_kitchen(occupied: bool) -> void:
	var doing: String = doing()
	wall(Color(0.8, 0.95, 0.87), "tiles")
	wooden_floor(Color(0.95, 0.8, 0.6))
	# checked floor strip under the table
	window(Rect2(490, 110, 200, 150), Color(1.0, 0.45, 0.45))
	# cupboards
	for door in 2:
		ThingDrawings.rounded_box(self, Rect2(200 + door * 130, 70, 120, 150), 10, Color(1.0, 0.82, 0.4))
		draw_circle(Vector2(200 + door * 130 + (100 if door == 0 else 20), 150), 7, INK)
	# counter and sink
	ThingDrawings.rounded_box(self, Rect2(170, 420, 610, 178), 6, Color(0.55, 0.78, 0.95))
	for door in 4:
		draw_rect(Rect2(190 + door * 148, 450, 130, 130), Color(0.55, 0.78, 0.95).lightened(0.15))
	draw_rect(Rect2(160, 396, 630, 28), WOOD)
	draw_line(Vector2(590, 396), Vector2(590, 340), Color(0.7, 0.72, 0.78), 10)
	draw_line(Vector2(590, 340), Vector2(630, 340), Color(0.7, 0.72, 0.78), 10)
	thing("jar", Vector2(260, 360), 0.45)
	# kettle
	ThingDrawings.shape(self, Vector2(720, 366), Vector2(34, 28), Color(0.95, 0.4, 0.45))
	# fridge
	var fridge := Rect2(20, 180, 130, 420)
	var fridge_open := occupied and doing == "drink"
	if fridge_open:
		ThingDrawings.rounded_box(self, fridge, 16, Color(0.9, 0.9, 0.85))
		draw_rect(fridge.grow(-14), Color(1.0, 0.98, 0.82))
		for shelf in 3:
			draw_line(Vector2(34, 300 + shelf * 100), Vector2(136, 300 + shelf * 100), WHITE.darkened(0.15), 4)
		thing("jar", Vector2(60, 270), 0.3)
		ThingDrawings.rounded_box(self, Rect2(95, 340, 26, 58), 6, WHITE)
		draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(78, 485), Vector2(28, 18)), Color(1.0, 0.85, 0.3))
		var door := PackedVector2Array([Vector2(150, 180), Vector2(215, 210), Vector2(215, 570), Vector2(150, 600)])
		draw_colored_polygon(door, WHITE.darkened(0.06))
		draw_polyline(door + PackedVector2Array([door[0]]), INK, 5)
	else:
		ThingDrawings.rounded_box(self, fridge, 16, WHITE.darkened(0.04))
		draw_line(Vector2(20, 330), Vector2(150, 330), INK, 4)
		draw_line(Vector2(130, 220), Vector2(130, 300), INK, 8)
		draw_line(Vector2(130, 360), Vector2(130, 460), INK, 8)
		draw_circle(Vector2(60, 240), 12, RED)
		draw_circle(Vector2(90, 270), 10, YELLOW)
	var at_table := occupied and doing == "meal"
	if at_table:
		blob(Vector2(290, 600), BIG, BLUE, "open", 0.0, Vector2(0, 0.8))
		blob(Vector2(430, 610), MIDDLE, RED, "open", 1.3, Vector2(0, 0.8))
		blob(Vector2(560, 590 + bounce(0.5, 10)), LITTLE, player_blob_colour, "happy", 2.6)
	# table with a checked cloth
	var top := Rect2(200, 640, 440, 30)
	draw_rect(Rect2(220, 670, 18, 80), WOOD.darkened(0.2))
	draw_rect(Rect2(602, 670, 18, 80), WOOD.darkened(0.2))
	draw_rect(top.grow(5), RED.darkened(0.4))
	draw_rect(top, WHITE)
	for square in 11:
		draw_rect(Rect2(200 + square * 40, 640 + (square % 2) * 15, 20, 15), RED.lightened(0.2))
	if at_table:
		draw_meal(acted_out_moment().get("meal", "tea"))
	if occupied and doing == "drink":
		blob(Vector2(250, 640), LITTLE, player_blob_colour, "open", 2.6, Vector2(-1, -0.4))
		var glass := Rect2(196, 630, 30, 44)
		draw_rect(glass.grow(3), INK)
		draw_rect(glass, Color(0.85, 0.95, 1.0))
		draw_rect(Rect2(196, 646, 30, 28), Color(0.6, 0.8, 1.0))
	var lights: Array = []
	if lamp_is_on(occupied):
		lights.append([Vector2(420, 108), 400.0])
	if fridge_open:
		lights.append([Vector2(85, 420), 260.0])
	pendant_lamp(420, lamp_is_on(occupied))
	night_shade(lights)


func draw_meal(meal: String) -> void:
	for seat in [Vector2(290, 640), Vector2(430, 640), Vector2(560, 640)]:
		match meal:
			"breakfast":
				thing("dish", seat + Vector2(0, -26), 0.42)
			"lunch":
				draw_colored_polygon(ThingDrawings.ellipse_points(seat + Vector2(0, -6), Vector2(46, 12)), WHITE)
				ThingDrawings.outlined_polygon(self, PackedVector2Array([seat + Vector2(-26, -10), seat + Vector2(20, -10), seat + Vector2(-26, -44)]), Color(1.0, 0.85, 0.55))
			"snack":
				ThingDrawings.shape(self, seat + Vector2(-10, -22), Vector2(18, 18), Color(0.95, 0.3, 0.3))
				draw_line(seat + Vector2(-10, -40), seat + Vector2(-6, -52), WOOD, 4)
				ThingDrawings.rounded_box(self, Rect2(seat + Vector2(16, -40), Vector2(24, 34)), 5, BLUE.lightened(0.4))
			_:
				draw_colored_polygon(ThingDrawings.ellipse_points(seat + Vector2(0, -6), Vector2(46, 12)), WHITE)
				for pea in 5:
					draw_circle(seat + Vector2(-18 + pea * 9, -10), 5, GREEN)
				ThingDrawings.shape(self, seat + Vector2(16, -14), Vector2(14, 8), Color(0.95, 0.65, 0.3))
	if meal == "breakfast":
		ThingDrawings.rounded_box(self, Rect2(360, 590, 30, 48), 6, WHITE)
	if meal == "tea":
		ThingDrawings.rounded_box(self, Rect2(340, 586, 70, 50), 10, Color(0.95, 0.5, 0.3))
	for steam in 3:
		var x := 300.0 + steam * 130 + sin(time * 2.0 + steam) * 6
		var rise := fposmod(time * 30.0 + steam * 20, 60)
		draw_arc(Vector2(x, 590 - rise), 10, PI * 0.5, PI * 1.5, 8, Color(1, 1, 1, 0.6 * (1.0 - rise / 60.0)), 4)


func draw_living_room(occupied: bool) -> void:
	var doing: String = doing()
	wall(Color(1.0, 0.87, 0.76), "stripes")
	wooden_floor(Color(0.78, 0.58, 0.42))
	window(Rect2(90, 110, 200, 160), Color(0.5, 0.8, 0.45))
	picture_frame(Rect2(370, 120, 150, 110), RED)
	# bookshelf
	ThingDrawings.rounded_box(self, Rect2(600, 150, 170, 450), 6, WOOD)
	for shelf in 4:
		var y := 170.0 + shelf * 108
		draw_rect(Rect2(614, y, 142, 88), WOOD.darkened(0.25))
		for book in 6:
			var height := 60.0 + fposmod(book * 37.0 + shelf * 11.0, 26)
			draw_rect(Rect2(618 + book * 22, y + 88 - height, 18, height), PaintColours.RAINBOW[(book + shelf) % 6])
	rug(Vector2(330, 700), Vector2(300, 46), Color(0.95, 0.55, 0.45))
	# plant
	ThingDrawings.rounded_box(self, Rect2(520, 620, 60, 60), 8, Color(0.9, 0.55, 0.35))
	for leaf in 5:
		ThingDrawings.shape(self, Vector2(550 + (leaf - 2) * 18, 590 - absf(leaf - 2) * -8 - 30), Vector2(12, 34), GREEN, (leaf - 2) * 0.35)
	pendant_lamp(380, lamp_is_on(occupied))
	# sofa
	var sofa := Color(0.35, 0.7, 0.75)
	ThingDrawings.rounded_box(self, Rect2(50, 440, 420, 150), 30, sofa)
	if occupied and doing == "sofa":
		blob(Vector2(150, 540), BIG, BLUE, "open", 0.0, Vector2(0.3, 0.8))
		blob(Vector2(285, 552), MIDDLE, RED, "open", 1.3, Vector2(-0.6, 0.6))
		blob(Vector2(395, 565), LITTLE, player_blob_colour, "closed", 2.6)
	ThingDrawings.rounded_box(self, Rect2(40, 570, 440, 70), 20, sofa.darkened(0.08))
	ThingDrawings.rounded_box(self, Rect2(26, 480, 50, 160), 22, sofa.darkened(0.15))
	ThingDrawings.rounded_box(self, Rect2(444, 480, 50, 160), 22, sofa.darkened(0.15))
	for leg_x in [70.0, 440.0]:
		draw_rect(Rect2(leg_x, 640, 16, 26), WOOD.darkened(0.3))
	if occupied and doing == "sofa":
		var book := PackedVector2Array([Vector2(150, 565), Vector2(210, 548), Vector2(210, 600), Vector2(150, 615), Vector2(90, 600), Vector2(90, 548)])
		draw_colored_polygon(book, WHITE)
		draw_polyline(book + PackedVector2Array([book[0]]), INK, 4)
		snore(Vector2(410, 500), 0.2)
	if occupied and doing == "painting":
		draw_painting_time()
	if occupied and doing == "sleepwalk":
		# eyes shut, arms out, slowly across the rug and back
		var walk_x: float = 330.0 + sin(time * 0.5) * 130.0
		for side in [-1.0, 1.0]:
			draw_line(Vector2(walk_x + side * 50, 670), Vector2(walk_x + side * 105, 650), player_blob_colour.darkened(0.35), 14)
		blob(Vector2(walk_x, 690 + bounce(0.0, 6)), MIDDLE, player_blob_colour, "closed", 2.6)
		snore(Vector2(walk_x + 40, 610), 0.5)
	var lights: Array = []
	if lamp_is_on(occupied):
		lights.append([Vector2(380, 108), 400.0])
	night_shade(lights)


func draw_painting_time() -> void:
	# paper on the floor with splats and pots
	var paper := PackedVector2Array([Vector2(90, 660), Vector2(400, 650), Vector2(430, 740), Vector2(70, 748)])
	draw_colored_polygon(paper, WHITE)
	draw_polyline(paper + PackedVector2Array([paper[0]]), INK.lightened(0.5), 3)
	for splat in 6:
		draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(130 + splat * 50, 690 + (splat % 2) * 26), Vector2(20, 12)), PaintColours.RAINBOW[splat])
	for pot in 3:
		var at := Vector2(470 + pot * 40, 720)
		ThingDrawings.rounded_box(self, Rect2(at - Vector2(15, 18), Vector2(30, 34)), 6, WHITE)
		draw_colored_polygon(ThingDrawings.ellipse_points(at - Vector2(0, 16), Vector2(13, 5)), [RED, YELLOW, BLUE][pot])
	# easel
	draw_line(Vector2(520, 690), Vector2(560, 450), WOOD.darkened(0.2), 10)
	draw_line(Vector2(620, 690), Vector2(580, 450), WOOD.darkened(0.2), 10)
	var canvas_rect := Rect2(480, 440, 170, 140)
	outlined_rect(canvas_rect, WHITE, 5)
	for arc_index in 4:
		draw_arc(canvas_rect.get_center() + Vector2(0, 50), 60 - arc_index * 12, PI, TAU, 16, PaintColours.RAINBOW[arc_index], 10)
	blob(Vector2(420, 600), MIDDLE, RED, "open", 1.3, Vector2(1, -0.3))
	var brush_tip := Vector2(470, 520 + sin(time * 5.0) * 14)
	draw_line(Vector2(440, 580), brush_tip, WOOD, 8)
	draw_circle(brush_tip, 8, RED)
	blob(Vector2(230, 700 + bounce(0.4, 8)), LITTLE, player_blob_colour, "happy", 2.6)
	draw_circle(Vector2(222, 680), 8, BLUE)
	blob(Vector2(140, 620), BIG, BLUE, "open", 0.0, Vector2(0.8, 0.4))


func draw_bathroom(occupied: bool) -> void:
	var bathing: bool = occupied and doing() == "bath"
	wall(Color(0.8, 0.9, 1.0), "tiles")
	draw_rect(Rect2(0, 0, ROOM.x, 300), Color(0.95, 0.92, 0.85))
	draw_line(Vector2(0, 300), Vector2(ROOM.x, 300), Color(0.6, 0.75, 0.9), 6)
	wooden_floor(Color(0.88, 0.85, 0.8))
	window(Rect2(560, 100, 160, 130), Color(0.6, 0.85, 0.95))
	# towels on a rail
	draw_line(Vector2(60, 140), Vector2(330, 140), Color(0.7, 0.72, 0.78), 8)
	for towel in 3:
		ThingDrawings.rounded_box(self, Rect2(76 + towel * 86, 140, 70, 110), 8, [RED, BLUE, YELLOW][towel].lightened(0.3))
	# sink and mirror
	draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(680, 330), Vector2(54, 64)), Color(0.85, 0.95, 1.0))
	draw_arc(Vector2(680, 330), 60, 0, TAU, 40, Color(0.95, 0.75, 0.35), 10)
	draw_rect(Rect2(665, 450, 30, 150), WHITE.darkened(0.06))
	draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(680, 440), Vector2(80, 24)), WHITE)
	draw_polyline(ThingDrawings.ellipse_points(Vector2(680, 440), Vector2(80, 24)), INK.lightened(0.4), 3)
	rug(Vector2(330, 720), Vector2(200, 30), Color(0.55, 0.85, 0.65))
	pendant_lamp(400, lamp_is_on(occupied))
	# the tub: blobs sit in it, then the front goes over them
	if bathing:
		blob(Vector2(150, 440), BIG, BLUE, "happy", 0.0)
		blob(Vector2(300, 452), MIDDLE, RED, "happy", 1.3)
		blob(Vector2(420, 470), LITTLE, player_blob_colour, "open", 2.6, Vector2(1, 0))
	var tub := PackedVector2Array()
	for step in 21:
		var angle := PI * step / 20.0
		tub.append(Vector2(290 + cos(angle) * 250, 520 + sin(angle) * 130))
	ThingDrawings.outlined_polygon(self, tub, WHITE.darkened(0.03))
	draw_rect(Rect2(30, 506, 520, 24), WHITE)
	draw_line(Vector2(30, 506), Vector2(550, 506), INK.lightened(0.3), 4)
	for foot_x in [110.0, 470.0]:
		ThingDrawings.shape(self, Vector2(foot_x, 640), Vector2(16, 14), Color(0.95, 0.75, 0.35))
	if bathing:
		for foam in 12:
			draw_circle(Vector2(60 + foam * 42, 505 + sin(foam * 1.7) * 6), 26, WHITE)
			draw_circle(Vector2(60 + foam * 42, 505 + sin(foam * 1.7) * 6) + Vector2(-6, -8), 8, Color(0.85, 0.93, 1.0))
		for bubble in 8:
			var rise := fposmod(time * 40.0 + bubble * 37.0, 260)
			var at := Vector2(80 + bubble * 60 + sin(time * 2.0 + bubble) * 12, 480 - rise)
			draw_arc(at, 10 + bubble % 3 * 5, 0, TAU, 16, Color(1, 1, 1, 0.8 * (1.0 - rise / 260.0)), 3)
		thing("duck", Vector2(500, 470 + sin(time * 2.0) * 4), 0.45)
	else:
		thing("duck", Vector2(500, 478), 0.4)
	var lights: Array = []
	if lamp_is_on(occupied):
		lights.append([Vector2(400, 108), 400.0])
	night_shade(lights)


## The garden as a whole room (close-up and peeping in use it).
func draw_garden_room(occupied: bool) -> void:
	draw_sky(Rect2(0, 0, ROOM.x, 520))
	draw_sky_visitors(Rect2(0, 0, ROOM.x, 520))
	draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(200, 560), Vector2(420, 130)), outdoor(GREEN.darkened(0.15)))
	draw_colored_polygon(ThingDrawings.ellipse_points(Vector2(680, 580), Vector2(380, 120)), outdoor(GREEN.darkened(0.08)))
	draw_rect(Rect2(0, 560, ROOM.x, 200), outdoor(GREEN))
	for picket in 17:
		var x := picket * 50.0
		var post := PackedVector2Array([Vector2(x + 6, 600), Vector2(x + 6, 470), Vector2(x + 22, 452), Vector2(x + 38, 470), Vector2(x + 38, 600)])
		draw_colored_polygon(post, outdoor(WHITE.darkened(0.04)))
		draw_polyline(post, outdoor(WHITE.darkened(0.3)), 3)
	draw_rect(Rect2(0, 500, ROOM.x, 14), outdoor(WHITE.darkened(0.1)))
	draw_garden_tree(Vector2(650, 600), 1.0)
	draw_bin(Vector2(70, 610))
	draw_flowers(Vector2(260, 650), 7, 1.0)
	draw_garden_doings(occupied, Vector2(400, 690), 1.0)


func draw_garden_tree(foot: Vector2, size: float) -> void:
	draw_rect(Rect2(foot.x - 20 * size, foot.y - 230 * size, 40 * size, 230 * size), outdoor(WOOD))
	for puff in 5:
		var at := foot + Vector2((puff - 2) * 50, -300 - absf(puff - 2) * -20 - (40 if puff == 2 else 0)) * size
		draw_circle(at, 80 * size, outdoor(GREEN.darkened(0.2)))
	for puff in 3:
		draw_circle(foot + Vector2((puff - 1) * 50, -330) * size, 62 * size, outdoor(GREEN.darkened(0.05)))
	for apple in 4:
		draw_circle(foot + Vector2(-70 + apple * 45, -290 + (apple % 2) * 40) * size, 10 * size, outdoor(RED))
	if visitor() == "owl":
		thing("owl", foot + Vector2(-10, -260) * size, 0.55 * size)


## A small brown hedgehog snuffling through the garden at night.
func draw_hedgehog(foot: Vector2, size: float) -> void:
	# Lit a little, like the moon is on it, so it shows in the dark garden
	var body: Color = Color(0.6, 0.45, 0.35)
	var middle: Vector2 = foot + Vector2(0, -22) * size
	for spike in 9:
		var angle: float = PI + PI * (spike + 0.5) / 9.0
		draw_line(middle, middle + Vector2.from_angle(angle) * 46 * size, body.darkened(0.3), 7 * size)
	draw_colored_polygon(ThingDrawings.ellipse_points(foot + Vector2(0, -20) * size, Vector2(40, 24) * size), body)
	draw_colored_polygon(ThingDrawings.ellipse_points(foot + Vector2(40, -14) * size, Vector2(18, 11) * size), Color(0.88, 0.76, 0.64))
	draw_circle(foot + Vector2(56, -14) * size, 5 * size, INK)
	draw_circle(foot + Vector2(38, -20) * size, 3.5 * size, INK)


func draw_bin(foot: Vector2) -> void:
	ThingDrawings.rounded_box(self, Rect2(foot - Vector2(36, 90), Vector2(72, 90)), 8, outdoor(Color(0.5, 0.55, 0.6)))
	draw_rect(Rect2(foot - Vector2(44, 100), Vector2(88, 16)), outdoor(Color(0.4, 0.45, 0.5)))
	if visitor() == "fox":
		thing("fox", foot + Vector2(80, -36), 0.7)


func draw_flowers(origin: Vector2, count: int, size: float) -> void:
	var growth := 1.3 if doing() == "watering" else 1.0
	for flower in count:
		var at := origin + Vector2(flower * 44, (flower % 3) * 20) * size
		draw_line(at, at + Vector2(0, 40) * size, outdoor(GREEN.darkened(0.3)), 5 * size)
		for petal in 5:
			draw_circle(at + Vector2.from_angle(TAU * petal / 5.0) * 11 * size * growth, 9 * size * growth, outdoor(PaintColours.RAINBOW[flower % 6].lightened(0.2)))
		draw_circle(at, 7 * size * growth, outdoor(YELLOW))


func draw_garden_doings(occupied: bool, centre: Vector2, size: float) -> void:
	if not occupied:
		return
	var doing: String = doing()
	if doing == "watering":
		blob(centre + Vector2(-60, 0) * size, BIG * size, BLUE, "open", 0.0, Vector2(-1, 0.3))
		ThingDrawings.rounded_box(self, Rect2(centre + Vector2(-190, -20) * size, Vector2(70, 50) * size), 8, outdoor(GREEN.darkened(0.1)))
		draw_line(centre + Vector2(-190, -10) * size, centre + Vector2(-240, -40) * size, outdoor(GREEN.darkened(0.1)), 10 * size)
		for drop in 5:
			var fall := fposmod(time * 1.5 + drop * 0.2, 1.0)
			draw_circle(centre + Vector2(-245 - drop * 6, -40 + fall * 70) * size, 5 * size, Color(0.5, 0.75, 1.0, 1.0 - fall))
		blob(centre + Vector2(110, 10 + bounce(0.6, 20)) * size, MIDDLE * size, RED, "happy", 1.3)
		blob(centre + Vector2(230, 20 + bounce(1.6, 26)) * size, LITTLE * size, player_blob_colour, "happy", 2.6)
		return
	var swing := sin(time * 2.2)
	blob(centre + Vector2(-170, bounce(0.0, 30)) * size, BIG * size, BLUE, "open", 0.0, Vector2(signf(swing), -0.4))
	blob(centre + Vector2(170, bounce(1.4, 40)) * size, MIDDLE * size, RED, "open", 1.3, Vector2(-signf(swing), -0.4))
	blob(centre + Vector2(20, 40 + bounce(2.0, 20)) * size, LITTLE * size, player_blob_colour, "happy", 2.6)
	thing("ball", centre + Vector2(swing * 130, -120 - absf(cos(time * 2.2)) * 60) * size, 0.55 * size)



# ---------------------------------------------------------------- B: busy doll's house

const DOLLS_ROOM_SCALE := 0.36


func draw_dolls_house() -> void:
	var ground_y := 962.0
	draw_rect(Rect2(PANEL.position + Vector2(0, 12), PANEL.size), Color(0, 0, 0, 0.12))
	draw_rect(PANEL.grow(10), INK)
	draw_sky(Rect2(PANEL.position, Vector2(PANEL.size.x, ground_y - PANEL.position.y)))
	draw_sky_visitors(Rect2(PANEL.position, Vector2(PANEL.size.x, 300)))
	draw_rect(Rect2(PANEL.position.x, ground_y, PANEL.size.x, PANEL.end.y - ground_y), outdoor(GREEN))
	var room_size := ROOM * DOLLS_ROOM_SCALE
	var left := PANEL.position.x + 30
	var downstairs_top := ground_y - room_size.y
	var upstairs_top := downstairs_top - 14 - room_size.y
	var house := Rect2(left, upstairs_top, room_size.x * 2 + 14, ground_y - upstairs_top)
	# roof with tiles and a chimney
	var chimney := Rect2(house.end.x - 140, upstairs_top - 120, 54, 90)
	outlined_rect(chimney, outdoor(Color(0.75, 0.4, 0.35)), 5)
	if lamp_on_anywhere():
		for puff in 3:
			var rise := fposmod(time * 20.0 + puff * 30, 60)
			draw_circle(chimney.position + Vector2(27 + sin(time + puff) * 8, -10 - rise), 14 + rise * 0.1, Color(1, 1, 1, 0.5 * (1.0 - rise / 60.0)))
	var roof := PackedVector2Array([Vector2(house.position.x - 30, upstairs_top), Vector2(house.get_center().x, upstairs_top - 150), Vector2(house.end.x + 30, upstairs_top)])
	draw_colored_polygon(roof, outdoor(RED.darkened(0.15)))
	for row in 4:
		var y := upstairs_top - 20 - row * 34
		var half := (y - (upstairs_top - 150)) / 150.0 * (house.size.x / 2.0 + 30)
		for tile in int(half * 2 / 40):
			draw_arc(Vector2(house.get_center().x - half + 20 + tile * 40, y), 18, 0, PI, 8, outdoor(RED.darkened(0.35)), 3)
	draw_polyline(roof + PackedVector2Array([roof[0]]), INK, 8)
	draw_rect(house.grow(10), outdoor(Color(0.95, 0.85, 0.7)))
	draw_rect(house.grow(10), INK, false, 6)
	var rooms := [["bedroom", Vector2(left, upstairs_top)], ["bathroom", Vector2(left + room_size.x + 14, upstairs_top)],
		["kitchen", Vector2(left, downstairs_top)], ["living", Vector2(left + room_size.x + 14, downstairs_top)]]
	for entry in rooms:
		begin_room(Rect2(entry[1], room_size))
		draw_room(entry[0], entry[0] == moment_room())
		if highlighted_room() != "" and entry[0] != highlighted_room():
			draw_rect(Rect2(Vector2.ZERO, ROOM), Color(0, 0, 0, OTHER_ROOMS_DIMMED))
		end_room()
	draw_line(Vector2(house.position.x, downstairs_top - 7), Vector2(house.end.x, downstairs_top - 7), INK, 14)
	draw_line(Vector2(left + room_size.x + 7, house.position.y), Vector2(left + room_size.x + 7, house.end.y), INK, 14)
	for entry in rooms:
		if entry[0] == highlighted_room():
			draw_rect(Rect2(entry[1], room_size).grow(-4), MOMENT_ROOM_OUTLINE, false, 8)
	# garden down the side
	var garden_left := house.end.x + 30
	begin_room(Rect2(Vector2(garden_left - 40, ground_y - 760 * 0.5), ROOM * 0.5))
	draw_garden_tree(Vector2(380, 760), 0.95)
	draw_bin(Vector2(120, 760))
	draw_flowers(Vector2(30, 790), 6, 0.9)
	if visitor() == "hedgehog":
		draw_hedgehog(Vector2(230 + sin(time * 0.4) * 50, 790), 1.8)
	end_room()
	if highlighted_room() == "garden":
		var garden_box: Rect2 = Rect2(Vector2(garden_left - 10, ground_y - 760 * 0.5), Vector2(PANEL.end.x - garden_left, 760 * 0.5 + 40))
		draw_rect(garden_box.grow(-8), MOMENT_ROOM_OUTLINE, false, 8)
	var playing_outside: bool = doing() == "play" or doing() == "watering"
	if moment_room() == "garden" and playing_outside:
		begin_room(Rect2(Vector2(garden_left - 70, ground_y - 760 * 0.42 + 10), ROOM * 0.42))
		draw_garden_doings(true, Vector2(400, 600), 0.8)
		end_room()


func lamp_on_anywhere() -> bool:
	return not is_a_night_doing(doing()) and darkness() > 0.2

