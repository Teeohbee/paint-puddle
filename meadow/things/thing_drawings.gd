class_name ThingDrawings
extends RefCounted
## Pictures of the things a word can turn into: spell DOG in the Meadow and a
## dog appears. Each picture is drawn round (0, 0), standing on the ground at
## y = GROUND_Y, about 120 wide. Shapes are polygons rather than transformed
## circles, so whatever draws them can squash and move them freely.

const GROUND_Y: float = 40.0
const OUTLINE_WIDTH: float = 4.0

const FUR_ORANGE: Color = Color(1.0, 0.6, 0.25)
const FUR_BROWN: Color = Color(0.72, 0.5, 0.32)
const FUR_WHITE: Color = Color(0.98, 0.97, 0.94)
const PIG_PINK: Color = Color(1.0, 0.72, 0.78)
const BEAK_ORANGE: Color = Color(1.0, 0.62, 0.18)
const WOOD_BROWN: Color = Color(0.66, 0.44, 0.26)
const LEAF_GREEN: Color = Color(0.36, 0.72, 0.34)
const FROG_GREEN: Color = Color(0.45, 0.82, 0.35)
const NEAR_BLACK: Color = Color(0.2, 0.18, 0.24)
const CARDBOARD: Color = Color(0.85, 0.66, 0.42)
const GOLD: Color = Color(1.0, 0.8, 0.3)
const GLASS: Color = Color(0.8, 0.93, 1.0, 0.55)

## Every thing that can be drawn, by name. The word is the name in capitals.
const NAMES: Array[String] = [
	"cat", "dog", "hen", "pig", "cow", "fox", "owl", "bee", "ant", "fish",
	"frog", "duck", "bus", "car", "sun", "hat", "box", "tree", "ball", "cake",
	"log", "bat", "pen", "bun", "bug", "jar", "dish", "bell",
]


static func can_draw(thing_name: String) -> bool:
	return NAMES.has(thing_name)


static func draw(canvas: CanvasItem, thing_name: String) -> void:
	match thing_name:
		"cat": draw_cat(canvas)
		"dog": draw_dog(canvas)
		"hen": draw_hen(canvas)
		"pig": draw_pig(canvas)
		"cow": draw_cow(canvas)
		"fox": draw_fox(canvas)
		"owl": draw_owl(canvas)
		"bee": draw_bee(canvas)
		"ant": draw_ant(canvas)
		"fish": draw_fish(canvas)
		"frog": draw_frog(canvas)
		"duck": draw_duck(canvas)
		"bus": draw_bus(canvas)
		"car": draw_car(canvas)
		"sun": draw_sun(canvas)
		"hat": draw_hat(canvas)
		"box": draw_box(canvas)
		"tree": draw_tree(canvas)
		"ball": draw_ball(canvas)
		"cake": draw_cake(canvas)
		"log": draw_log(canvas)
		"bat": draw_bat(canvas)
		"pen": draw_pen(canvas)
		"bun": draw_bun(canvas)
		"bug": draw_bug(canvas)
		"jar": draw_jar(canvas)
		"dish": draw_dish(canvas)
		"bell": draw_bell(canvas)


# --- Building blocks -------------------------------------------------------

static func ellipse_points(centre: Vector2, radii: Vector2, rotation: float = 0.0, point_count: int = 32) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in point_count:
		var angle: float = TAU * point_index / point_count
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation))
	return points


## A filled ellipse with a darker rim, like the blob and the paint pots.
static func shape(canvas: CanvasItem, centre: Vector2, radii: Vector2, colour: Color, rotation: float = 0.0) -> void:
	canvas.draw_colored_polygon(ellipse_points(centre, radii + Vector2.ONE * OUTLINE_WIDTH, rotation), colour.darkened(0.35))
	canvas.draw_colored_polygon(ellipse_points(centre, radii, rotation), colour)


## A filled ellipse with no rim, for patches and markings on top of a shape.
static func patch(canvas: CanvasItem, centre: Vector2, radii: Vector2, colour: Color, rotation: float = 0.0) -> void:
	canvas.draw_colored_polygon(ellipse_points(centre, radii, rotation), colour)


static func outlined_polygon(canvas: CanvasItem, points: PackedVector2Array, colour: Color) -> void:
	canvas.draw_colored_polygon(points, colour)
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, colour.darkened(0.35), OUTLINE_WIDTH, true)


static func rounded_box(canvas: CanvasItem, rect: Rect2, corner_radius: float, colour: Color) -> void:
	var outline: Rect2 = rect.grow(OUTLINE_WIDTH)
	draw_rounded_rect(canvas, outline, corner_radius + OUTLINE_WIDTH, colour.darkened(0.35))
	draw_rounded_rect(canvas, rect, corner_radius, colour)


static func draw_rounded_rect(canvas: CanvasItem, rect: Rect2, corner_radius: float, colour: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [
		rect.position + Vector2(rect.size.x - corner_radius, corner_radius),
		rect.position + rect.size - Vector2(corner_radius, corner_radius),
		rect.position + Vector2(corner_radius, rect.size.y - corner_radius),
		rect.position + Vector2(corner_radius, corner_radius),
	]
	for corner_index in 4:
		var start_angle: float = -PI / 2.0 + corner_index * PI / 2.0
		for step in 7:
			var angle: float = start_angle + step * (PI / 2.0) / 6.0
			points.append(corners[corner_index] + Vector2.from_angle(angle) * corner_radius)
	canvas.draw_colored_polygon(points, colour)


static func eye(canvas: CanvasItem, centre: Vector2, radius: float = 7.0) -> void:
	canvas.draw_circle(centre, radius, Color.WHITE)
	canvas.draw_circle(centre + Vector2(0, radius * 0.15), radius * 0.6, PaintColours.INK)
	canvas.draw_circle(centre + Vector2(-radius * 0.2, -radius * 0.15), radius * 0.22, Color.WHITE)


static func smile(canvas: CanvasItem, centre: Vector2, width: float) -> void:
	canvas.draw_arc(centre, width, 0.4, PI - 0.4, 10, PaintColours.INK, 3.0, true)


static func shine(canvas: CanvasItem, centre: Vector2, radius: float) -> void:
	patch(canvas, centre, Vector2(radius, radius * 0.6), Color(1, 1, 1, 0.45), -0.6)


static func leg(canvas: CanvasItem, top: Vector2, colour: Color, width: float = 10.0) -> void:
	canvas.draw_line(top, Vector2(top.x, GROUND_Y), colour.darkened(0.35), width + OUTLINE_WIDTH, true)
	canvas.draw_line(top, Vector2(top.x, GROUND_Y - OUTLINE_WIDTH * 0.5), colour, width, true)


static func wheel(canvas: CanvasItem, centre: Vector2, radius: float) -> void:
	canvas.draw_circle(centre, radius, NEAR_BLACK)
	canvas.draw_circle(centre, radius * 0.45, Color(0.75, 0.75, 0.8))


# --- Animals ---------------------------------------------------------------

static func draw_cat(canvas: CanvasItem) -> void:
	canvas.draw_arc(Vector2(42, -2), 22, -PI * 0.9, 0.2, 12, FUR_ORANGE.darkened(0.35), 12, true)
	canvas.draw_arc(Vector2(42, -2), 22, -PI * 0.9, 0.2, 12, FUR_ORANGE, 8, true)
	for leg_x in [-24.0, -8.0, 12.0, 28.0]:
		leg(canvas, Vector2(leg_x, 20), FUR_ORANGE, 9)
	shape(canvas, Vector2(4, 12), Vector2(40, 22), FUR_ORANGE)
	for ear_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(-28 + ear_side * 16, -36), Vector2(-28 + ear_side * 22, -62),
			Vector2(-28 + ear_side * 4, -46)]), FUR_ORANGE)
	shape(canvas, Vector2(-28, -24), Vector2(26, 23), FUR_ORANGE)
	for stripe_x in [0.0, 14.0, 28.0]:
		canvas.draw_line(Vector2(stripe_x, -6), Vector2(stripe_x - 4, 6), FUR_ORANGE.darkened(0.25), 5, true)
	eye(canvas, Vector2(-38, -28), 6)
	eye(canvas, Vector2(-18, -28), 6)
	canvas.draw_circle(Vector2(-28, -18), 3.5, PIG_PINK.darkened(0.2))
	for whisker_side in [-1.0, 1.0]:
		for whisker_tilt in [-4.0, 3.0]:
			canvas.draw_line(Vector2(-28 + whisker_side * 8, -16), Vector2(-28 + whisker_side * 30, -16 + whisker_tilt), PaintColours.INK, 1.5, true)


static func draw_dog(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(38, 0), Vector2(56, -22), FUR_BROWN.darkened(0.35), 12, true)
	canvas.draw_line(Vector2(38, 0), Vector2(56, -22), FUR_BROWN, 8, true)
	for leg_x in [-24.0, -8.0, 12.0, 28.0]:
		leg(canvas, Vector2(leg_x, 20), FUR_BROWN, 10)
	shape(canvas, Vector2(4, 10), Vector2(42, 24), FUR_BROWN)
	patch(canvas, Vector2(14, 4), Vector2(14, 10), FUR_WHITE)
	shape(canvas, Vector2(-30, -24), Vector2(26, 24), FUR_BROWN)
	shape(canvas, Vector2(-54, -22), Vector2(9, 19), FUR_BROWN.darkened(0.3), 0.3)
	shape(canvas, Vector2(-6, -22), Vector2(9, 19), FUR_BROWN.darkened(0.3), -0.3)
	patch(canvas, Vector2(-30, -12), Vector2(14, 10), FUR_WHITE)
	canvas.draw_circle(Vector2(-30, -17), 5, PaintColours.INK)
	eye(canvas, Vector2(-40, -30), 6)
	eye(canvas, Vector2(-20, -30), 6)
	smile(canvas, Vector2(-30, -14), 6)


static func draw_hen(canvas: CanvasItem) -> void:
	for leg_x in [-8.0, 10.0]:
		canvas.draw_line(Vector2(leg_x, 18), Vector2(leg_x, GROUND_Y), BEAK_ORANGE, 5, true)
	outlined_polygon(canvas, PackedVector2Array([Vector2(26, -8), Vector2(52, -34), Vector2(46, 6)]), FUR_WHITE)
	shape(canvas, Vector2(4, 0), Vector2(36, 28), FUR_WHITE)
	shape(canvas, Vector2(8, 4), Vector2(18, 12), Color(0.92, 0.9, 0.86), 0.3)
	shape(canvas, Vector2(-24, -30), Vector2(18, 18), FUR_WHITE)
	for comb_x in [-30.0, -22.0, -14.0]:
		canvas.draw_circle(Vector2(comb_x, -48), 6, PaintColours.RED)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-40, -32), Vector2(-54, -26), Vector2(-40, -22)]), BEAK_ORANGE)
	patch(canvas, Vector2(-38, -16), Vector2(4, 7), PaintColours.RED)
	eye(canvas, Vector2(-28, -34), 5)


static func draw_pig(canvas: CanvasItem) -> void:
	canvas.draw_arc(Vector2(48, -4), 8, PI * 0.5, PI * 2.3, 12, PIG_PINK.darkened(0.35), 4, true)
	for leg_x in [-24.0, -8.0, 14.0, 28.0]:
		leg(canvas, Vector2(leg_x, 22), PIG_PINK, 11)
	shape(canvas, Vector2(6, 8), Vector2(44, 28), PIG_PINK)
	for ear_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(-26 + ear_side * 6, -38), Vector2(-26 + ear_side * 24, -52),
			Vector2(-26 + ear_side * 20, -30)]), PIG_PINK)
	shape(canvas, Vector2(-26, -20), Vector2(28, 26), PIG_PINK)
	shape(canvas, Vector2(-26, -10), Vector2(13, 9), PIG_PINK.darkened(0.08))
	canvas.draw_circle(Vector2(-31, -10), 3, PIG_PINK.darkened(0.45))
	canvas.draw_circle(Vector2(-21, -10), 3, PIG_PINK.darkened(0.45))
	eye(canvas, Vector2(-38, -28), 5)
	eye(canvas, Vector2(-14, -28), 5)


static func draw_cow(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(44, 0), Vector2(52, 24), FUR_WHITE.darkened(0.35), 5, true)
	canvas.draw_circle(Vector2(52, 26), 5, NEAR_BLACK)
	for leg_x in [-26.0, -10.0, 16.0, 32.0]:
		leg(canvas, Vector2(leg_x, 18), FUR_WHITE, 10)
		canvas.draw_line(Vector2(leg_x, GROUND_Y - 6), Vector2(leg_x, GROUND_Y - 2), NEAR_BLACK, 10)
	shape(canvas, Vector2(6, 2), Vector2(46, 26), FUR_WHITE)
	patch(canvas, Vector2(18, -6), Vector2(14, 10), NEAR_BLACK, 0.4)
	patch(canvas, Vector2(-6, 12), Vector2(10, 8), NEAR_BLACK, -0.3)
	patch(canvas, Vector2(36, 12), Vector2(7, 6), NEAR_BLACK)
	for horn_side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(-30 + horn_side * 12, -40), Vector2(-30 + horn_side * 22, -54), Color(0.95, 0.88, 0.7), 6, true)
		shape(canvas, Vector2(-30 + horn_side * 26, -34), Vector2(11, 6), FUR_WHITE, horn_side * 0.4)
	shape(canvas, Vector2(-30, -26), Vector2(22, 22), FUR_WHITE)
	shape(canvas, Vector2(-30, -10), Vector2(18, 11), PIG_PINK)
	canvas.draw_circle(Vector2(-36, -10), 2.5, PIG_PINK.darkened(0.45))
	canvas.draw_circle(Vector2(-24, -10), 2.5, PIG_PINK.darkened(0.45))
	eye(canvas, Vector2(-39, -32), 5)
	eye(canvas, Vector2(-21, -32), 5)


static func draw_fox(canvas: CanvasItem) -> void:
	shape(canvas, Vector2(44, -8), Vector2(28, 14), FUR_ORANGE, -0.7)
	patch(canvas, Vector2(60, -24), Vector2(10, 8), FUR_WHITE, -0.7)
	for leg_x in [-22.0, -8.0, 12.0, 26.0]:
		leg(canvas, Vector2(leg_x, 20), NEAR_BLACK, 8)
	shape(canvas, Vector2(4, 10), Vector2(38, 20), FUR_ORANGE)
	patch(canvas, Vector2(-18, 14), Vector2(12, 10), FUR_WHITE)
	for ear_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(-28 + ear_side * 6, -38), Vector2(-28 + ear_side * 20, -64),
			Vector2(-28 + ear_side * 22, -34)]), FUR_ORANGE)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-54, -32), Vector2(-2, -32), Vector2(-28, 2)]), FUR_ORANGE)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-48, -20), Vector2(-28, -18), Vector2(-28, 0)]), FUR_WHITE)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, -20), Vector2(-28, -18), Vector2(-28, 0)]), FUR_WHITE)
	canvas.draw_circle(Vector2(-28, -2), 4, PaintColours.INK)
	eye(canvas, Vector2(-37, -24), 5)
	eye(canvas, Vector2(-19, -24), 5)


static func draw_owl(canvas: CanvasItem) -> void:
	for foot_x in [-12.0, 12.0]:
		canvas.draw_line(Vector2(foot_x, 30), Vector2(foot_x, GROUND_Y), BEAK_ORANGE, 6, true)
	for tuft_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(tuft_side * 14, -40), Vector2(tuft_side * 34, -62),
			Vector2(tuft_side * 32, -30)]), FUR_BROWN)
	shape(canvas, Vector2(0, -4), Vector2(36, 40), FUR_BROWN)
	patch(canvas, Vector2(0, 14), Vector2(22, 20), Color(0.95, 0.86, 0.7))
	for feather_y in [8.0, 18.0, 28.0]:
		canvas.draw_arc(Vector2(0, feather_y), 6, 0.3, PI - 0.3, 6, FUR_BROWN, 2.0, true)
	for eye_side in [-1.0, 1.0]:
		canvas.draw_circle(Vector2(eye_side * 15, -16), 15, Color(0.95, 0.86, 0.7))
		eye(canvas, Vector2(eye_side * 15, -16), 10)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-5, -8), Vector2(5, -8), Vector2(0, 2)]), BEAK_ORANGE)


static func draw_bee(canvas: CanvasItem) -> void:
	var wing_colour: Color = Color(0.85, 0.95, 1.0, 0.85)
	shape(canvas, Vector2(-6, -36), Vector2(16, 22), wing_colour, -0.4)
	shape(canvas, Vector2(14, -34), Vector2(14, 20), wing_colour, 0.4)
	shape(canvas, Vector2(4, 0), Vector2(40, 28), PaintColours.YELLOW)
	for stripe_x in [-2.0, 18.0]:
		canvas.draw_line(Vector2(stripe_x, -24), Vector2(stripe_x, 24), NEAR_BLACK, 10)
	outlined_polygon(canvas, PackedVector2Array([Vector2(42, -4), Vector2(56, 0), Vector2(42, 4)]), NEAR_BLACK)
	shape(canvas, Vector2(-30, -2), Vector2(18, 18), NEAR_BLACK)
	for antenna_side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(-34 + antenna_side * 4, -16), Vector2(-42 + antenna_side * 8, -34), NEAR_BLACK, 3, true)
		canvas.draw_circle(Vector2(-42 + antenna_side * 8, -34), 4, NEAR_BLACK)
	eye(canvas, Vector2(-36, -4), 6)
	shine(canvas, Vector2(10, -14), 8)


static func draw_ant(canvas: CanvasItem) -> void:
	var ant_red: Color = Color(0.62, 0.22, 0.2)
	for leg_index in 3:
		var leg_x: float = -12.0 + leg_index * 14.0
		canvas.draw_line(Vector2(leg_x, 14), Vector2(leg_x - 10, GROUND_Y), NEAR_BLACK, 4, true)
		canvas.draw_line(Vector2(leg_x, 14), Vector2(leg_x + 10, GROUND_Y), NEAR_BLACK, 4, true)
	shape(canvas, Vector2(30, 8), Vector2(24, 20), ant_red)
	shape(canvas, Vector2(0, 10), Vector2(14, 12), ant_red)
	shape(canvas, Vector2(-30, -2), Vector2(20, 19), ant_red)
	for antenna_side in [-1.0, 1.0]:
		canvas.draw_polyline(PackedVector2Array([Vector2(-34 + antenna_side * 5, -18), Vector2(-40 + antenna_side * 6, -38),
			Vector2(-52 + antenna_side * 6, -44)]), NEAR_BLACK, 3, true)
	eye(canvas, Vector2(-38, -6), 6)
	eye(canvas, Vector2(-22, -6), 6)
	shine(canvas, Vector2(24, 0), 7)


static func draw_fish(canvas: CanvasItem) -> void:
	var fish_orange: Color = Color(1.0, 0.55, 0.2)
	outlined_polygon(canvas, PackedVector2Array([Vector2(28, -4), Vector2(58, -28), Vector2(58, 20)]), fish_orange)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-6, -24), Vector2(14, -40), Vector2(20, -20)]), fish_orange)
	shape(canvas, Vector2(-4, -4), Vector2(40, 26), fish_orange)
	for stripe_x in [4.0, 18.0]:
		canvas.draw_arc(Vector2(stripe_x, -4), 22, -0.9, 0.9, 10, FUR_WHITE, 5, true)
	eye(canvas, Vector2(-24, -10), 8)
	smile(canvas, Vector2(-34, 2), 5)
	shine(canvas, Vector2(-8, -18), 7)


static func draw_frog(canvas: CanvasItem) -> void:
	for foot_side in [-1.0, 1.0]:
		shape(canvas, Vector2(foot_side * 30, 32), Vector2(16, 8), FROG_GREEN)
	shape(canvas, Vector2(0, 8), Vector2(42, 30), FROG_GREEN)
	patch(canvas, Vector2(0, 18), Vector2(26, 16), Color(0.8, 0.95, 0.6))
	for eye_side in [-1.0, 1.0]:
		shape(canvas, Vector2(eye_side * 20, -22), Vector2(15, 15), FROG_GREEN)
		eye(canvas, Vector2(eye_side * 20, -24), 10)
	canvas.draw_arc(Vector2(0, -6), 22, 0.3, PI - 0.3, 14, PaintColours.INK, 3.0, true)
	canvas.draw_circle(Vector2(-30, 0), 4, PIG_PINK)
	canvas.draw_circle(Vector2(30, 0), 4, PIG_PINK)


static func draw_duck(canvas: CanvasItem) -> void:
	var duck_yellow: Color = Color(1.0, 0.86, 0.3)
	for foot_x in [-6.0, 12.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(foot_x - 2, 24), Vector2(foot_x + 2, 24),
			Vector2(foot_x + 10, GROUND_Y), Vector2(foot_x - 10, GROUND_Y)]), BEAK_ORANGE)
	outlined_polygon(canvas, PackedVector2Array([Vector2(30, -2), Vector2(52, -18), Vector2(44, 10)]), duck_yellow)
	shape(canvas, Vector2(6, 6), Vector2(40, 24), duck_yellow)
	shape(canvas, Vector2(14, 4), Vector2(18, 10), duck_yellow.darkened(0.1), 0.3)
	shape(canvas, Vector2(-24, -28), Vector2(20, 20), duck_yellow)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-40, -28), Vector2(-60, -22), Vector2(-40, -16)]), BEAK_ORANGE)
	eye(canvas, Vector2(-28, -34), 6)


static func draw_bat(canvas: CanvasItem) -> void:
	var bat_purple: Color = Color(0.45, 0.35, 0.6)
	for wing_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([
			Vector2(wing_side * 14, -14), Vector2(wing_side * 40, -36), Vector2(wing_side * 62, -22),
			Vector2(wing_side * 52, -10), Vector2(wing_side * 42, 2), Vector2(wing_side * 28, -4), Vector2(wing_side * 16, 8),
		]), bat_purple)
	for ear_side in [-1.0, 1.0]:
		outlined_polygon(canvas, PackedVector2Array([Vector2(ear_side * 6, -28), Vector2(ear_side * 16, -48),
			Vector2(ear_side * 20, -22)]), bat_purple)
	shape(canvas, Vector2(0, -6), Vector2(22, 26), bat_purple)
	patch(canvas, Vector2(0, 4), Vector2(12, 14), bat_purple.lightened(0.25))
	eye(canvas, Vector2(-8, -14), 6)
	eye(canvas, Vector2(8, -14), 6)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4, -2), Vector2(-1, -2), Vector2(-2.5, 3)]), Color.WHITE)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1, -2), Vector2(4, -2), Vector2(2.5, 3)]), Color.WHITE)
	for foot_x in [-6.0, 6.0]:
		canvas.draw_line(Vector2(foot_x, 18), Vector2(foot_x, GROUND_Y - 8), bat_purple.darkened(0.35), 4, true)


static func draw_bug(canvas: CanvasItem) -> void:
	for leg_index in 3:
		var leg_x: float = -16.0 + leg_index * 16.0
		canvas.draw_line(Vector2(leg_x, 14), Vector2(leg_x - 6, GROUND_Y), NEAR_BLACK, 4, true)
	shape(canvas, Vector2(-36, 2), Vector2(18, 16), NEAR_BLACK)
	shape(canvas, Vector2(6, 0), Vector2(40, 30), PaintColours.RED)
	canvas.draw_line(Vector2(-30, 0), Vector2(46, 0), NEAR_BLACK, 4, true)
	for spot in [Vector2(-8, -14), Vector2(22, -12), Vector2(-4, 14), Vector2(26, 14), Vector2(8, -2)]:
		canvas.draw_circle(spot, 6, NEAR_BLACK)
	for antenna_side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(-44, -6 + antenna_side * 4), Vector2(-56, -20 + antenna_side * 6), NEAR_BLACK, 3, true)
	eye(canvas, Vector2(-42, -2), 5)
	shine(canvas, Vector2(14, -18), 8)


# --- Things ----------------------------------------------------------------

static func draw_bus(canvas: CanvasItem) -> void:
	rounded_box(canvas, Rect2(-60, -46, 120, 72), 14, PaintColours.RED)
	for window_index in 4:
		rounded_box(canvas, Rect2(-50 + window_index * 26, -36, 20, 22), 5, Color(0.75, 0.9, 1.0))
	canvas.draw_line(Vector2(-60, 0), Vector2(60, 0), FUR_WHITE, 5)
	rounded_box(canvas, Rect2(46, -36, 8, 10), 2, GOLD)
	wheel(canvas, Vector2(-34, 28), 13)
	wheel(canvas, Vector2(34, 28), 13)


static func draw_car(canvas: CanvasItem) -> void:
	outlined_polygon(canvas, PackedVector2Array([Vector2(-30, -10), Vector2(-20, -40), Vector2(22, -40), Vector2(36, -10)]), PaintColours.BLUE)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-22, -12), Vector2(-14, -34), Vector2(0, -34), Vector2(0, -12)]), Color(0.75, 0.9, 1.0))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(6, -12), Vector2(6, -34), Vector2(18, -34), Vector2(28, -12)]), Color(0.75, 0.9, 1.0))
	rounded_box(canvas, Rect2(-56, -14, 112, 36), 14, PaintColours.BLUE)
	canvas.draw_circle(Vector2(-50, -2), 5, PaintColours.YELLOW)
	shine(canvas, Vector2(-24, -6), 8)
	wheel(canvas, Vector2(-32, 26), 14)
	wheel(canvas, Vector2(32, 26), 14)


static func draw_sun(canvas: CanvasItem) -> void:
	var centre: Vector2 = Vector2(0, -10)
	for ray_index in 10:
		var angle: float = TAU * ray_index / 10.0
		outlined_polygon(canvas, PackedVector2Array([
			centre + Vector2.from_angle(angle - 0.18) * 34, centre + Vector2.from_angle(angle) * 54,
			centre + Vector2.from_angle(angle + 0.18) * 34,
		]), BEAK_ORANGE)
	shape(canvas, centre, Vector2(36, 36), PaintColours.YELLOW)
	eye(canvas, centre + Vector2(-12, -6), 6)
	eye(canvas, centre + Vector2(12, -6), 6)
	smile(canvas, centre + Vector2(0, 4), 12)
	canvas.draw_circle(centre + Vector2(-22, 6), 5, Color(1.0, 0.55, 0.45, 0.6))
	canvas.draw_circle(centre + Vector2(22, 6), 5, Color(1.0, 0.55, 0.45, 0.6))


static func draw_hat(canvas: CanvasItem) -> void:
	shape(canvas, Vector2(0, 28), Vector2(60, 12), NEAR_BLACK)
	rounded_box(canvas, Rect2(-34, -50, 68, 78), 6, NEAR_BLACK)
	canvas.draw_rect(Rect2(-34, 6, 68, 14), PaintColours.RED)
	shape(canvas, Vector2(26, 6), Vector2(8, 8), PaintColours.YELLOW)
	shine(canvas, Vector2(-20, -34), 8)


static func draw_box(canvas: CanvasItem) -> void:
	outlined_polygon(canvas, PackedVector2Array([Vector2(-46, -30), Vector2(-62, -48), Vector2(-20, -48), Vector2(-4, -30)]), CARDBOARD.lightened(0.1))
	outlined_polygon(canvas, PackedVector2Array([Vector2(46, -30), Vector2(62, -48), Vector2(20, -48), Vector2(4, -30)]), CARDBOARD.lightened(0.1))
	rounded_box(canvas, Rect2(-46, -30, 92, 70), 3, CARDBOARD)
	canvas.draw_rect(Rect2(-8, -30, 16, 70), Color(0.95, 0.86, 0.62))
	canvas.draw_line(Vector2(-30, 20), Vector2(-14, 20), CARDBOARD.darkened(0.3), 3, true)


static func draw_tree(canvas: CanvasItem) -> void:
	rounded_box(canvas, Rect2(-10, -6, 20, 46), 4, WOOD_BROWN)
	shape(canvas, Vector2(-22, -24), Vector2(26, 24), LEAF_GREEN)
	shape(canvas, Vector2(22, -24), Vector2(26, 24), LEAF_GREEN)
	shape(canvas, Vector2(0, -46), Vector2(30, 28), LEAF_GREEN)
	patch(canvas, Vector2(-22, -24), Vector2(22, 20), LEAF_GREEN)
	patch(canvas, Vector2(22, -24), Vector2(22, 20), LEAF_GREEN)
	patch(canvas, Vector2(-10, -54), Vector2(12, 8), LEAF_GREEN.lightened(0.25), -0.4)
	for apple in [Vector2(-26, -20), Vector2(18, -36), Vector2(4, -14), Vector2(28, -12), Vector2(-12, -48)]:
		canvas.draw_circle(apple, 6, PaintColours.RED)
		canvas.draw_circle(apple + Vector2(-2, -2), 2, Color(1, 1, 1, 0.7))


static func draw_ball(canvas: CanvasItem) -> void:
	var centre: Vector2 = Vector2(0, -4)
	var radius: float = 42.0
	canvas.draw_circle(centre, radius + OUTLINE_WIDTH, PaintColours.INK.lightened(0.2))
	var segment_colours: Array[Color] = [PaintColours.RED, FUR_WHITE, PaintColours.BLUE, FUR_WHITE, PaintColours.YELLOW, FUR_WHITE]
	for segment_index in segment_colours.size():
		var points: PackedVector2Array = PackedVector2Array([centre])
		var start_angle: float = TAU * segment_index / segment_colours.size() - PI / 2.0
		for step in 9:
			points.append(centre + Vector2.from_angle(start_angle + step * TAU / segment_colours.size() / 8.0) * radius)
		canvas.draw_colored_polygon(points, segment_colours[segment_index])
	canvas.draw_circle(centre, 8, FUR_WHITE)
	shine(canvas, centre + Vector2(-18, -18), 10)


static func draw_cake(canvas: CanvasItem) -> void:
	rounded_box(canvas, Rect2(-50, -6, 100, 44), 6, Color(0.95, 0.75, 0.55))
	canvas.draw_rect(Rect2(-50, 10, 100, 8), PaintColours.RED.lightened(0.2))
	rounded_box(canvas, Rect2(-50, -16, 100, 14), 7, Color(1.0, 0.82, 0.88))
	for drip_x in [-36.0, -14.0, 10.0, 32.0]:
		patch(canvas, Vector2(drip_x, -2), Vector2(6, 9), Color(1.0, 0.82, 0.88))
	rounded_box(canvas, Rect2(-4, -48, 8, 32), 3, PaintColours.BLUE.lightened(0.3))
	patch(canvas, Vector2(0, -56), Vector2(6, 10), BEAK_ORANGE)
	patch(canvas, Vector2(0, -54), Vector2(3, 5), PaintColours.YELLOW)
	for cherry_x in [-30.0, 30.0]:
		canvas.draw_circle(Vector2(cherry_x, -20), 6, PaintColours.RED)


static func draw_log(canvas: CanvasItem) -> void:
	rounded_box(canvas, Rect2(-56, -10, 100, 44), 20, WOOD_BROWN)
	for bark_y in [2.0, 14.0, 24.0]:
		canvas.draw_line(Vector2(-40, bark_y), Vector2(20, bark_y), WOOD_BROWN.darkened(0.2), 3, true)
	shape(canvas, Vector2(44, 12), Vector2(14, 22), Color(0.9, 0.75, 0.5))
	for ring_size in [14.0, 8.0]:
		canvas.draw_arc(Vector2(44, 12), ring_size * 0.6, 0, TAU, 16, WOOD_BROWN.darkened(0.1), 2, true)
	patch(canvas, Vector2(-12, -12), Vector2(10, 6), LEAF_GREEN)


static func draw_pen(canvas: CanvasItem) -> void:
	var angle: float = -0.6
	var along: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = along.orthogonal()
	var back: Vector2 = Vector2(-44, 22)
	var front: Vector2 = back + along * 80
	outlined_polygon(canvas, PackedVector2Array([back + across * 10, front + across * 10, front - across * 10, back - across * 10]),
		PaintColours.BLUE)
	outlined_polygon(canvas, PackedVector2Array([front + across * 10, front + along * 22, front - across * 10]), Color(0.95, 0.88, 0.7))
	canvas.draw_circle(front + along * 18, 3.5, PaintColours.INK)
	canvas.draw_line(back + along * 14 + across * 10, back + along * 14 - across * 10, GOLD, 5)
	canvas.draw_line(back + along * 6 + across * 6, back + along * 46 + across * 6, GOLD, 4, true)


static func draw_bun(canvas: CanvasItem) -> void:
	shape(canvas, Vector2(0, 14), Vector2(50, 24), Color(0.92, 0.66, 0.36))
	shape(canvas, Vector2(0, 0), Vector2(46, 24), FUR_WHITE)
	for drip_x in [-30.0, -6.0, 20.0]:
		patch(canvas, Vector2(drip_x, 18), Vector2(7, 10), FUR_WHITE)
	canvas.draw_circle(Vector2(0, -26), 11, PaintColours.RED)
	canvas.draw_circle(Vector2(-3, -29), 3, Color(1, 1, 1, 0.7))
	canvas.draw_line(Vector2(0, -36), Vector2(8, -50), LEAF_GREEN.darkened(0.2), 3, true)
	for sprinkle in [Vector2(-24, -6), Vector2(20, -10), Vector2(-8, 6), Vector2(30, 4)]:
		canvas.draw_line(sprinkle, sprinkle + Vector2(6, -3), PaintColours.BLUE, 3, true)


static func draw_jar(canvas: CanvasItem) -> void:
	rounded_box(canvas, Rect2(-36, -30, 72, 70), 16, GLASS)
	rounded_box(canvas, Rect2(-32, -6, 64, 42), 12, PaintColours.RED.darkened(0.1))
	rounded_box(canvas, Rect2(-40, -46, 80, 18), 4, Color(0.95, 0.88, 0.7))
	canvas.draw_rect(Rect2(-40, -38, 80, 4), PaintColours.RED.lightened(0.3))
	rounded_box(canvas, Rect2(-20, 2, 40, 22), 4, FUR_WHITE)
	canvas.draw_circle(Vector2(0, 13), 6, PaintColours.RED)
	shine(canvas, Vector2(-22, -16), 7)


static func draw_dish(canvas: CanvasItem) -> void:
	var bowl_blue: Color = PaintColours.BLUE.lightened(0.35)
	var bowl: PackedVector2Array = PackedVector2Array()
	for step in 17:
		var angle: float = PI * step / 16.0
		bowl.append(Vector2(cos(angle) * 56, -4 + sin(angle) * 40))
	outlined_polygon(canvas, bowl, bowl_blue)
	rounded_box(canvas, Rect2(-20, 32, 40, 8), 3, bowl_blue)
	shape(canvas, Vector2(0, -4), Vector2(56, 12), bowl_blue.lightened(0.3))
	patch(canvas, Vector2(0, -2), Vector2(46, 8), Color(1.0, 0.55, 0.3))
	for dot_x in [-24.0, 0.0, 22.0]:
		canvas.draw_circle(Vector2(dot_x, -4), 4, Color(1.0, 0.85, 0.4))
	canvas.draw_line(Vector2(-40, 12), Vector2(40, 12), FUR_WHITE, 4, true)
	shine(canvas, Vector2(-34, 14), 6)


static func draw_bell(canvas: CanvasItem) -> void:
	canvas.draw_arc(Vector2(0, -50), 8, PI, TAU, 10, GOLD.darkened(0.35), 4, true)
	outlined_polygon(canvas, PackedVector2Array([
		Vector2(-20, -40), Vector2(20, -40), Vector2(30, -10), Vector2(36, 18), Vector2(48, 28),
		Vector2(-48, 28), Vector2(-36, 18), Vector2(-30, -10),
	]), GOLD)
	canvas.draw_circle(Vector2(0, 34), 9, GOLD.darkened(0.2))
	canvas.draw_line(Vector2(-40, 20), Vector2(40, 20), GOLD.darkened(0.2), 4)
	shine(canvas, Vector2(-14, -24), 7)
