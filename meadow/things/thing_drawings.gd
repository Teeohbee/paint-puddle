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
	"rabbit", "rocket", "castle", "penguin", "octopus", "giraffe", "snowman",
	"tractor", "dinosaur", "elephant", "umbrella", "crocodile", "helicopter", "caterpillar",
	"kangaroo", "panda", "pyramid", "tower",
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
		"rabbit": draw_rabbit(canvas)
		"rocket": draw_rocket(canvas)
		"castle": draw_castle(canvas)
		"penguin": draw_penguin(canvas)
		"octopus": draw_octopus(canvas)
		"giraffe": draw_giraffe(canvas)
		"snowman": draw_snowman(canvas)
		"tractor": draw_tractor(canvas)
		"dinosaur": draw_dinosaur(canvas)
		"elephant": draw_elephant(canvas)
		"umbrella": draw_umbrella(canvas)
		"crocodile": draw_crocodile(canvas)
		"helicopter": draw_helicopter(canvas)
		"caterpillar": draw_caterpillar(canvas)
		"kangaroo": draw_kangaroo(canvas)
		"panda": draw_panda(canvas)
		"pyramid": draw_pyramid(canvas)
		"tower": draw_tower(canvas)


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


# --- Long words ------------------------------------------------------------

const GREY_ELEPHANT: Color = Color(0.68, 0.7, 0.78)
const GIRAFFE_YELLOW: Color = Color(1.0, 0.8, 0.35)
const CROC_GREEN: Color = Color(0.38, 0.66, 0.36)
const DINO_TEAL: Color = Color(0.36, 0.72, 0.68)


static func draw_rabbit(canvas: CanvasItem) -> void:
	var fur: Color = Color(0.92, 0.9, 0.88)
	shape(canvas, Vector2(34, 14), Vector2(12, 11), Color.WHITE)
	shape(canvas, Vector2(6, 16), Vector2(32, 24), fur)
	shape(canvas, Vector2(-14, 34), Vector2(14, 7), fur)
	for ear_x in [-30.0, -14.0]:
		shape(canvas, Vector2(ear_x, -50), Vector2(8, 24), fur, (ear_x + 22) * 0.02)
		patch(canvas, Vector2(ear_x, -48), Vector2(4, 17), PIG_PINK, (ear_x + 22) * 0.02)
	shape(canvas, Vector2(-22, -16), Vector2(22, 20), fur)
	eye(canvas, Vector2(-31, -20), 5)
	eye(canvas, Vector2(-13, -20), 5)
	canvas.draw_circle(Vector2(-22, -9), 3.5, PIG_PINK.darkened(0.2))
	for whisker_side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(-22 + whisker_side * 6, -7), Vector2(-22 + whisker_side * 24, -10), PaintColours.INK, 1.5, true)


static func draw_rocket(canvas: CanvasItem) -> void:
	outlined_polygon(canvas, PackedVector2Array([Vector2(-20, 10), Vector2(-40, 36), Vector2(-20, 30)]), PaintColours.RED)
	outlined_polygon(canvas, PackedVector2Array([Vector2(20, 10), Vector2(40, 36), Vector2(20, 30)]), PaintColours.RED)
	patch(canvas, Vector2(0, 40), Vector2(12, 14), BEAK_ORANGE)
	patch(canvas, Vector2(0, 38), Vector2(6, 8), PaintColours.YELLOW)
	var body: PackedVector2Array = PackedVector2Array()
	for step in 13:
		var t: float = step / 12.0
		body.append(Vector2(-22 * sin(t * PI * 0.5 + 0.2), lerpf(-70, 32, t)))
	for step in 13:
		var t: float = 1.0 - step / 12.0
		body.append(Vector2(22 * sin(t * PI * 0.5 + 0.2), lerpf(-70, 32, t)))
	outlined_polygon(canvas, body, FUR_WHITE)
	canvas.draw_circle(Vector2(0, -16), 12, PaintColours.BLUE.darkened(0.35))
	canvas.draw_circle(Vector2(0, -16), 9, Color(0.75, 0.9, 1.0))
	canvas.draw_line(Vector2(-18, 14), Vector2(18, 14), PaintColours.RED, 6)
	shine(canvas, Vector2(-8, -40), 5)


static func draw_castle(canvas: CanvasItem) -> void:
	var stone: Color = Color(0.78, 0.76, 0.82)
	for tower_x in [-44.0, 44.0]:
		rounded_box(canvas, Rect2(tower_x - 14, -40, 28, 80), 2, stone)
		outlined_polygon(canvas, PackedVector2Array([Vector2(tower_x - 18, -40), Vector2(tower_x, -68), Vector2(tower_x + 18, -40)]), PaintColours.RED)
	rounded_box(canvas, Rect2(-30, -20, 60, 60), 2, stone)
	for battlement_x in [-30.0, -12.0, 6.0, 24.0]:
		canvas.draw_rect(Rect2(battlement_x, -30, 10, 10), stone.darkened(0.1))
	rounded_box(canvas, Rect2(-12, 10, 24, 30), 10, WOOD_BROWN)
	canvas.draw_line(Vector2(44, -68), Vector2(44, -86), PaintColours.INK, 2)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(44, -86), Vector2(60, -81), Vector2(44, -76)]), PaintColours.YELLOW)
	for window_x in [-44.0, 44.0]:
		rounded_box(canvas, Rect2(window_x - 5, -24, 10, 14), 4, PaintColours.INK.lightened(0.2))


static func draw_penguin(canvas: CanvasItem) -> void:
	for foot_side in [-1.0, 1.0]:
		shape(canvas, Vector2(foot_side * 12, 36), Vector2(11, 5), BEAK_ORANGE)
	shape(canvas, Vector2(0, -2), Vector2(32, 40), NEAR_BLACK)
	shape(canvas, Vector2(-30, 2), Vector2(8, 22), NEAR_BLACK, 0.3)
	shape(canvas, Vector2(30, 2), Vector2(8, 22), NEAR_BLACK, -0.3)
	patch(canvas, Vector2(0, 6), Vector2(22, 30), FUR_WHITE)
	patch(canvas, Vector2(0, -22), Vector2(20, 14), FUR_WHITE)
	eye(canvas, Vector2(-9, -24), 6)
	eye(canvas, Vector2(9, -24), 6)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-6, -16), Vector2(6, -16), Vector2(0, -6)]), BEAK_ORANGE)
	canvas.draw_circle(Vector2(-16, -12), 4, Color(1.0, 0.5, 0.55, 0.5))
	canvas.draw_circle(Vector2(16, -12), 4, Color(1.0, 0.5, 0.55, 0.5))


static func draw_octopus(canvas: CanvasItem) -> void:
	var octopus_pink: Color = Color(0.95, 0.45, 0.65)
	for leg_index in 6:
		var leg_x: float = -40.0 + leg_index * 16.0
		var wiggle: PackedVector2Array = PackedVector2Array()
		for step in 7:
			var t: float = step / 6.0
			wiggle.append(Vector2(leg_x + sin(t * PI * 2.0 + leg_index) * 7.0 + (leg_x * 0.25) * t, lerpf(6, 38, t)))
		canvas.draw_polyline(wiggle, octopus_pink.darkened(0.35), 14, true)
		canvas.draw_polyline(wiggle, octopus_pink, 10, true)
	shape(canvas, Vector2(0, -16), Vector2(38, 34), octopus_pink)
	for spot in [Vector2(-18, -34), Vector2(14, -38), Vector2(24, -18)]:
		canvas.draw_circle(spot, 4, octopus_pink.lightened(0.3))
	eye(canvas, Vector2(-12, -12), 8)
	eye(canvas, Vector2(12, -12), 8)
	smile(canvas, Vector2(0, -2), 8)
	shine(canvas, Vector2(-20, -30), 7)


static func draw_giraffe(canvas: CanvasItem) -> void:
	var spots_colour: Color = Color(0.78, 0.5, 0.24)
	for leg_x in [-4.0, 8.0, 26.0, 38.0]:
		leg(canvas, Vector2(leg_x, 10), GIRAFFE_YELLOW, 7)
	canvas.draw_line(Vector2(44, -2), Vector2(56, 18), GIRAFFE_YELLOW.darkened(0.35), 4, true)
	shape(canvas, Vector2(18, 0), Vector2(30, 16), GIRAFFE_YELLOW)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-6, -6), Vector2(-28, -62), Vector2(-16, -66), Vector2(10, -8)]), GIRAFFE_YELLOW)
	for spot in [Vector2(10, -4), Vector2(28, 2), Vector2(-14, -34), Vector2(-20, -52), Vector2(-6, -18)]:
		patch(canvas, spot, Vector2(5, 4), spots_colour)
	for horn_x in [-30.0, -20.0]:
		canvas.draw_line(Vector2(horn_x, -74), Vector2(horn_x, -86), spots_colour, 4, true)
		canvas.draw_circle(Vector2(horn_x, -87), 3.5, spots_colour)
	shape(canvas, Vector2(-30, -70), Vector2(18, 11), GIRAFFE_YELLOW, -0.2)
	patch(canvas, Vector2(-42, -66), Vector2(8, 6), GIRAFFE_YELLOW.lightened(0.3))
	eye(canvas, Vector2(-30, -74), 5)


static func draw_snowman(canvas: CanvasItem) -> void:
	var snow: Color = Color(0.97, 0.98, 1.0)
	var snow_rim: Color = Color(0.72, 0.78, 0.88)
	for ball in [[Vector2(0, 16), 28.0], [Vector2(0, -26), 20.0]]:
		canvas.draw_circle(ball[0], ball[1] + OUTLINE_WIDTH, snow_rim)
		canvas.draw_circle(ball[0], ball[1], snow)
	for button_y in [6.0, 18.0, 30.0]:
		canvas.draw_circle(Vector2(0, button_y), 3.5, NEAR_BLACK)
	canvas.draw_rect(Rect2(-18, -48, 36, 6), NEAR_BLACK)
	canvas.draw_rect(Rect2(-12, -70, 24, 24), NEAR_BLACK)
	canvas.draw_rect(Rect2(-12, -52, 24, 4), PaintColours.RED)
	eye(canvas, Vector2(-7, -30), 4)
	eye(canvas, Vector2(7, -30), 4)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(0, -20), Vector2(-18, -22)]), BEAK_ORANGE)
	canvas.draw_line(Vector2(-14, -8), Vector2(18, -6), PaintColours.RED, 7, true)
	canvas.draw_line(Vector2(12, -6), Vector2(16, 10), PaintColours.RED, 7, true)
	canvas.draw_line(Vector2(-26, 8), Vector2(-48, -8), WOOD_BROWN, 3, true)
	canvas.draw_line(Vector2(26, 8), Vector2(48, -8), WOOD_BROWN, 3, true)


static func draw_tractor(canvas: CanvasItem) -> void:
	var tractor_green: Color = Color(0.3, 0.68, 0.32)
	rounded_box(canvas, Rect2(-50, -6, 70, 26), 6, tractor_green)
	rounded_box(canvas, Rect2(-4, -46, 40, 50), 4, tractor_green)
	rounded_box(canvas, Rect2(2, -40, 28, 20), 3, Color(0.75, 0.9, 1.0))
	canvas.draw_rect(Rect2(-40, -24, 8, 18), NEAR_BLACK)
	wheel(canvas, Vector2(-34, 26), 14)
	canvas.draw_circle(Vector2(24, 18), 24, NEAR_BLACK)
	canvas.draw_circle(Vector2(24, 18), 12, PaintColours.YELLOW)
	shine(canvas, Vector2(-34, 2), 5)


static func draw_dinosaur(canvas: CanvasItem) -> void:
	for leg_x in [-10.0, 6.0, 24.0, 36.0]:
		leg(canvas, Vector2(leg_x, 16), DINO_TEAL, 11)
	outlined_polygon(canvas, PackedVector2Array([Vector2(36, 0), Vector2(66, 26), Vector2(30, 18)]), DINO_TEAL)
	for plate_index in 5:
		var plate_x: float = -14.0 + plate_index * 12.0
		outlined_polygon(canvas, PackedVector2Array([Vector2(plate_x - 6, -16), Vector2(plate_x, -30), Vector2(plate_x + 6, -16)]), PaintColours.ORANGE)
	shape(canvas, Vector2(12, 4), Vector2(34, 22), DINO_TEAL)
	canvas.draw_line(Vector2(-14, -2), Vector2(-34, -40), DINO_TEAL.darkened(0.35), 16, true)
	canvas.draw_line(Vector2(-14, -2), Vector2(-34, -40), DINO_TEAL, 12, true)
	shape(canvas, Vector2(-42, -46), Vector2(16, 11), DINO_TEAL)
	eye(canvas, Vector2(-44, -50), 5)
	smile(canvas, Vector2(-48, -44), 5)
	patch(canvas, Vector2(14, 12), Vector2(20, 9), DINO_TEAL.lightened(0.25))


static func draw_elephant(canvas: CanvasItem) -> void:
	for leg_x in [-14.0, 2.0, 24.0, 38.0]:
		leg(canvas, Vector2(leg_x, 16), GREY_ELEPHANT, 13)
	canvas.draw_line(Vector2(50, 0), Vector2(58, 18), GREY_ELEPHANT.darkened(0.35), 4, true)
	shape(canvas, Vector2(14, 2), Vector2(38, 26), GREY_ELEPHANT)
	shape(canvas, Vector2(-14, -18), Vector2(20, 24), GREY_ELEPHANT.lightened(0.1))
	patch(canvas, Vector2(-14, -18), Vector2(13, 17), PIG_PINK.darkened(0.05))
	shape(canvas, Vector2(-34, -20), Vector2(20, 19), GREY_ELEPHANT)
	var trunk: PackedVector2Array = PackedVector2Array([Vector2(-48, -14), Vector2(-56, 4), Vector2(-56, 20), Vector2(-48, 28)])
	canvas.draw_polyline(trunk, GREY_ELEPHANT.darkened(0.35), 16, true)
	canvas.draw_polyline(trunk, GREY_ELEPHANT, 12, true)
	eye(canvas, Vector2(-40, -26), 5)
	canvas.draw_circle(Vector2(-28, -12), 4, Color(1.0, 0.5, 0.55, 0.5))


static func draw_umbrella(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(0, -40), Vector2(0, 30), WOOD_BROWN.darkened(0.2), 5, true)
	canvas.draw_arc(Vector2(-10, 30), 10, 0.0, PI, 10, WOOD_BROWN.darkened(0.2), 5, true)
	var canopy_colours: Array[Color] = [PaintColours.RED, PaintColours.YELLOW, PaintColours.BLUE, PaintColours.GREEN]
	for panel_index in 4:
		var start_angle: float = PI + panel_index * PI / 4.0
		var points: PackedVector2Array = PackedVector2Array([Vector2(0, -6)])
		for step in 7:
			points.append(Vector2(0, -6) + Vector2.from_angle(start_angle + step * PI / 24.0) * Vector2(58, 52))
		canvas.draw_colored_polygon(points, canopy_colours[panel_index])
	canvas.draw_line(Vector2(-58, -6), Vector2(58, -6), PaintColours.INK.lightened(0.3), 3, true)
	canvas.draw_circle(Vector2(0, -60), 4, NEAR_BLACK)
	shine(canvas, Vector2(-26, -34), 7)


static func draw_crocodile(canvas: CanvasItem) -> void:
	for leg_x in [-20.0, 24.0]:
		shape(canvas, Vector2(leg_x, 30), Vector2(9, 10), CROC_GREEN)
	outlined_polygon(canvas, PackedVector2Array([Vector2(30, 6), Vector2(66, 22), Vector2(30, 28)]), CROC_GREEN)
	shape(canvas, Vector2(4, 16), Vector2(36, 14), CROC_GREEN)
	rounded_box(canvas, Rect2(-64, 4, 40, 16), 7, CROC_GREEN)
	for tooth_x in [-58.0, -48.0, -38.0]:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(tooth_x, 20), Vector2(tooth_x + 6, 20), Vector2(tooth_x + 3, 26)]), Color.WHITE)
	for bump_x in [-6.0, 8.0, 22.0]:
		canvas.draw_circle(Vector2(bump_x, 4), 4, CROC_GREEN.darkened(0.2))
	shape(canvas, Vector2(-28, 0), Vector2(9, 9), CROC_GREEN)
	eye(canvas, Vector2(-28, -2), 6)
	patch(canvas, Vector2(0, 22), Vector2(28, 5), Color(0.8, 0.9, 0.5))


static func draw_helicopter(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(-60, -52), Vector2(40, -52), NEAR_BLACK, 5, true)
	canvas.draw_line(Vector2(-8, -52), Vector2(-8, -36), NEAR_BLACK, 4)
	rounded_box(canvas, Rect2(10, -18, 50, 10), 4, PaintColours.ORANGE)
	canvas.draw_line(Vector2(60, -28), Vector2(60, 2), NEAR_BLACK, 4, true)
	shape(canvas, Vector2(-14, -12), Vector2(36, 26), PaintColours.ORANGE)
	patch(canvas, Vector2(-30, -16), Vector2(16, 14), Color(0.75, 0.9, 1.0))
	canvas.draw_line(Vector2(-36, 28), Vector2(14, 28), NEAR_BLACK, 4, true)
	canvas.draw_line(Vector2(-26, 14), Vector2(-28, 28), NEAR_BLACK, 4, true)
	canvas.draw_line(Vector2(4, 14), Vector2(6, 28), NEAR_BLACK, 4, true)
	shine(canvas, Vector2(-2, -26), 7)


static func draw_caterpillar(canvas: CanvasItem) -> void:
	var segment_colours: Array[Color] = [LEAF_GREEN, FROG_GREEN, LEAF_GREEN, FROG_GREEN, LEAF_GREEN]
	for segment_index in range(4, -1, -1):
		var segment_centre: Vector2 = Vector2(48 - segment_index * 22, 18 - absf(sin(segment_index * 1.1)) * 10)
		canvas.draw_line(segment_centre + Vector2(-4, 12), segment_centre + Vector2(-6, 20), NEAR_BLACK, 3, true)
		shape(canvas, segment_centre, Vector2(15, 15), segment_colours[segment_index])
	shape(canvas, Vector2(-50, -2), Vector2(18, 18), PaintColours.RED)
	for antenna_side in [-1.0, 1.0]:
		canvas.draw_line(Vector2(-50 + antenna_side * 6, -18), Vector2(-50 + antenna_side * 12, -32), NEAR_BLACK, 3, true)
		canvas.draw_circle(Vector2(-50 + antenna_side * 12, -32), 4, PaintColours.YELLOW)
	eye(canvas, Vector2(-56, -4), 5)
	eye(canvas, Vector2(-44, -4), 5)
	smile(canvas, Vector2(-50, 4), 5)


static func draw_kangaroo(canvas: CanvasItem) -> void:
	var fur: Color = Color(0.85, 0.55, 0.32)
	var belly: Color = Color(0.97, 0.85, 0.68)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-14, 10), Vector2(-60, 38), Vector2(-20, 38)]), fur)
	shape(canvas, Vector2(-8, 12), Vector2(28, 34), fur, -0.15)
	patch(canvas, Vector2(-2, 14), Vector2(15, 22), belly)
	shape(canvas, Vector2(6, 38), Vector2(26, 7), fur)
	shape(canvas, Vector2(14, -22), Vector2(15, 17), fur)
	shape(canvas, Vector2(26, -14), Vector2(13, 9), fur)
	for ear_tilt in [-0.3, 0.3]:
		shape(canvas, Vector2(8 + ear_tilt * 30, -48), Vector2(5, 15), fur, ear_tilt)
	shape(canvas, Vector2(14, 6), Vector2(6, 14), fur, 0.5)
	eye(canvas, Vector2(18, -26), 5)
	canvas.draw_circle(Vector2(36, -16), 4, PaintColours.INK)


static func draw_panda(canvas: CanvasItem) -> void:
	for ear_side in [-1.0, 1.0]:
		shape(canvas, Vector2(ear_side * 28, -36), Vector2(12, 12), NEAR_BLACK)
	shape(canvas, Vector2(0, 22), Vector2(34, 28), FUR_WHITE)
	for leg_side in [-1.0, 1.0]:
		shape(canvas, Vector2(leg_side * 28, 34), Vector2(12, 14), NEAR_BLACK)
		shape(canvas, Vector2(leg_side * 36, 8), Vector2(10, 18), NEAR_BLACK, leg_side * 0.4)
	shape(canvas, Vector2(0, -12), Vector2(34, 30), FUR_WHITE)
	for eye_side in [-1.0, 1.0]:
		patch(canvas, Vector2(eye_side * 13, -14), Vector2(9, 12), NEAR_BLACK, eye_side * 0.4)
		canvas.draw_circle(Vector2(eye_side * 13, -15), 3.5, Color.WHITE)
	shape(canvas, Vector2(0, -2), Vector2(7, 5), NEAR_BLACK)
	smile(canvas, Vector2(0, 6), 12)


static func draw_pyramid(canvas: CanvasItem) -> void:
	var sand: Color = Color(0.95, 0.8, 0.45)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-70, 40), Vector2(70, 40), Vector2(0, -50)]), sand)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -50), Vector2(70, 40), Vector2(14, 40)]), sand.darkened(0.15))
	for block_row in 3:
		var row_y: float = -14.0 + block_row * 18.0
		var half_width: float = (row_y + 50.0) / 90.0 * 70.0
		canvas.draw_line(Vector2(-half_width, row_y), Vector2(half_width, row_y), sand.darkened(0.3), 2)
	canvas.draw_circle(Vector2(-62, -40), 12, GOLD)


static func draw_tower(canvas: CanvasItem) -> void:
	var iron: Color = Color(0.5, 0.42, 0.4)
	outlined_polygon(canvas, PackedVector2Array([Vector2(-36, 44), Vector2(-24, 44), Vector2(-4, -6), Vector2(4, -6), Vector2(24, 44), Vector2(36, 44), Vector2(8, -50), Vector2(-8, -50)]), iron)
	rounded_box(canvas, Rect2(-24, 6, 48, 8), 2, iron)
	rounded_box(canvas, Rect2(-14, -22, 28, 7), 2, iron)
	canvas.draw_line(Vector2(0, -50), Vector2(0, -72), iron.darkened(0.35), 4)
	canvas.draw_arc(Vector2(0, 44), 18, PI, TAU, 12, iron.darkened(0.35), 4)
