class_name TracingLetters
extends RefCounted
## The lowercase letters to trace, in the order school teaches them (Read
## Write Inc. Set 1), each with its rhyme. A letter is one or more strokes;
## a stroke is the dots to paint, in order, from where school says to start.
##
## Letters are drawn on a writing grid where the x-height runs from y 0 to 1,
## ascenders reach up to -1 and descenders down to 2, then each letter is
## scaled to fill the play area on its own: a, o and the rest of the small
## letters come out bigger than b or g. Angles are degrees on screen (y down):
## 0 is right, -90 is up, so anticlockwise means the angle going down.

const ORDER: String = "masdtinpgockubfelhrjvywzxq"
const RHYMES: Dictionary = {
	"m": "Maisie, mountain, mountain",
	"a": "Round the apple, down the leaf",
	"s": "Slither down the snake",
	"d": "Round the dinosaur's bottom, up its tall neck and down to the feet",
	"t": "Down the tower, across the tower",
	"i": "Down the insect's body, dot for the head",
	"n": "Down Nobby, over his net",
	"p": "Down the plait and over the pirate's face",
	"g": "Round her face, down her hair and give her a curl",
	"o": "All around the orange",
	"c": "Curl around the caterpillar",
	"k": "Down the kangaroo's body, tail and leg",
	"u": "Down and under, up to the top and draw the puddle",
	"b": "Down the laces to the heel, round the toe",
	"f": "Down the stem and draw the leaves",
	"e": "Lift off the top and scoop out the egg",
	"l": "Down the long leg",
	"h": "Down the head to the hooves and over its back",
	"r": "Down its back, then curl over its arm",
	"j": "Down its body, curl and dot",
	"v": "Down a wing, up a wing",
	"y": "Down a horn, up a horn and under its head",
	"w": "Down, up, down, up",
	"z": "Zig-zag-zig",
	"x": "Down the arm and leg and repeat the other side",
	"q": "Round her head, up past her earrings, down her hair and flick",
}
## Where letters go: inside the hedge by the blob's radius, under the rhyme card.
const PLAY_AREA: Rect2 = Rect2(360, 200, 1200, 760)
## The biggest a grid unit gets, so a small letter doesn't swamp the meadow.
const BIGGEST_UNIT: float = 560.0
const DOT_SPACING: float = 38.0
## Points along a curve, before they're thinned out into dots.
const SAMPLE_SPACING: float = 0.01
## Round letters start at about 2 o'clock.
const ROUND_START: float = -35.0


static func rhyme_for(letter: String) -> String:
	return RHYMES.get(letter, "")


## The letter's strokes as dots on screen, each stroke in drawing order.
static func strokes_for(letter: String) -> Array[PackedVector2Array]:
	var grid_strokes: Array[PackedVector2Array] = grid_strokes_for(letter)
	var box: Rect2 = Rect2(grid_strokes[0][0], Vector2.ZERO)
	for stroke in grid_strokes:
		for point in stroke:
			box = box.expand(point)
	var unit: float = BIGGEST_UNIT
	if box.size.x > 0.0:
		unit = minf(unit, PLAY_AREA.size.x / box.size.x)
	if box.size.y > 0.0:
		unit = minf(unit, PLAY_AREA.size.y / box.size.y)
	var offset: Vector2 = PLAY_AREA.get_center() - box.get_center() * unit
	var strokes: Array[PackedVector2Array] = []
	for stroke in grid_strokes:
		var on_screen: PackedVector2Array = []
		for point in stroke:
			on_screen.append(offset + point * unit)
		strokes.append(dots_along(on_screen))
	return strokes


## Thins a dense line of points into dots DOT_SPACING apart, keeping both ends.
static func dots_along(points: PackedVector2Array) -> PackedVector2Array:
	var dots: PackedVector2Array = [points[0]]
	var since_last: float = 0.0
	for point_index in range(1, points.size()):
		since_last += points[point_index].distance_to(points[point_index - 1])
		if since_last >= DOT_SPACING:
			dots.append(points[point_index])
			since_last = 0.0
	if since_last > DOT_SPACING * 0.4:
		dots.append(points[points.size() - 1])
	return dots


## Each letter on the writing grid, as school forms it. Going back up a
## stem before a hump ("Down Nobby, over his net") retraces it, as a pencil does.
static func grid_strokes_for(letter: String) -> Array[PackedVector2Array]:
	var bowl: Vector2 = Vector2(0.5, 0.5)
	match letter:
		"m":
			return [path([line(0, 0, 0, 1), line(0, 1, 0, 0.3), arc(Vector2(0.3, 0.3), 0.3, 180, 360),
				line(0.6, 0.3, 0.6, 1), line(0.6, 1, 0.6, 0.3), arc(Vector2(0.9, 0.3), 0.3, 180, 360), line(1.2, 0.3, 1.2, 1)])]
		"a":
			return [path([arc(bowl, 0.5, ROUND_START, -360), line(1, 0.5, 1, 0), line(1, 0, 1, 1)])]
		"s":
			return [path([arc(Vector2(0.5, 0.25), 0.25, -30, -270), arc(Vector2(0.5, 0.75), 0.25, -90, 150)])]
		"d":
			return [path([arc(bowl, 0.5, ROUND_START, -360), line(1, 0.5, 1, -1), line(1, -1, 1, 1)])]
		"t":
			return [path([line(0.3, -0.6, 0.3, 1)]), path([line(0, 0, 0.6, 0)])]
		"i":
			return [path([line(0, 0, 0, 1)]), PackedVector2Array([Vector2(0, -0.45)])]
		"n":
			return [path([line(0, 0, 0, 1), line(0, 1, 0, 0.4), arc(Vector2(0.4, 0.4), 0.4, 180, 360), line(0.8, 0.4, 0.8, 1)])]
		"p":
			return [path([line(0, 0, 0, 2), line(0, 2, 0, 0.5), arc(bowl, 0.5, 180, 540)])]
		"g":
			return [path([arc(bowl, 0.5, ROUND_START, -360), line(1, 0.5, 1, 0), line(1, 0, 1, 1.6),
				arc(Vector2(0.6, 1.6), 0.4, 0, 160)])]
		"o":
			return [path([arc(bowl, 0.5, ROUND_START, ROUND_START - 360)])]
		"c":
			return [path([arc(bowl, 0.5, ROUND_START, -320)])]
		"k":
			return [path([line(0, -1, 0, 1), line(0, 1, 0, 0.55), line(0, 0.55, 0.6, 0), line(0.6, 0, 0.05, 0.55),
				line(0.05, 0.55, 0.65, 1)])]
		"u":
			return [path([line(0, 0, 0, 0.6), arc(Vector2(0.4, 0.6), 0.4, 180, 0), line(0.8, 0.6, 0.8, 0), line(0.8, 0, 0.8, 1)])]
		"b":
			return [path([line(0, -1, 0, 1), line(0, 1, 0, 0.5), arc(bowl, 0.5, 180, 540)])]
		"f":
			return [path([arc(Vector2(0.55, -0.6), 0.3, -20, -180), line(0.25, -0.6, 0.25, 1)]), path([line(0, 0, 0.55, 0)])]
		"e":
			return [path([line(0, 0.5, 1, 0.5), arc(bowl, 0.5, 0, -320)])]
		"l":
			return [path([line(0, -1, 0, 1)])]
		"h":
			return [path([line(0, -1, 0, 1), line(0, 1, 0, 0.4), arc(Vector2(0.4, 0.4), 0.4, 180, 360), line(0.8, 0.4, 0.8, 1)])]
		"r":
			return [path([line(0, 0, 0, 1), line(0, 1, 0, 0.4), arc(Vector2(0.4, 0.4), 0.4, 180, 320)])]
		"j":
			return [path([line(0.6, 0, 0.6, 1.6), arc(Vector2(0.2, 1.6), 0.4, 0, 160)]), PackedVector2Array([Vector2(0.6, -0.45)])]
		"v":
			return [path([line(0, 0, 0.45, 1), line(0.45, 1, 0.9, 0)])]
		"y":
			return [path([line(0, 0, 0.45, 1), line(0.45, 1, 0.9, 0), line(0.9, 0, 0.2, 2)])]
		"w":
			return [path([line(0, 0, 0.3, 1), line(0.3, 1, 0.6, 0.2), line(0.6, 0.2, 0.9, 1), line(0.9, 1, 1.2, 0)])]
		"z":
			return [path([line(0, 0, 0.9, 0), line(0.9, 0, 0, 1), line(0, 1, 0.9, 1)])]
		"x":
			return [path([line(0, 0, 0.9, 1)]), path([line(0.9, 0, 0, 1)])]
		"q":
			return [path([arc(bowl, 0.5, ROUND_START, -360), line(1, 0.5, 1, 0), line(1, 0, 1, 2), line(1, 2, 1.3, 1.75)])]
	push_warning("No letter %s to trace" % letter)
	return [PackedVector2Array([Vector2.ZERO])]


## Pieces joined end to end into one stroke.
static func path(pieces: Array[PackedVector2Array]) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for piece in pieces:
		points.append_array(piece)
	return points


static func line(from_x: float, from_y: float, to_x: float, to_y: float) -> PackedVector2Array:
	var from: Vector2 = Vector2(from_x, from_y)
	var to: Vector2 = Vector2(to_x, to_y)
	var steps: int = maxi(1, ceili(from.distance_to(to) / SAMPLE_SPACING))
	var points: PackedVector2Array = []
	for step in steps + 1:
		points.append(from.lerp(to, float(step) / steps))
	return points


static func arc(centre: Vector2, radius: float, from_degrees: float, to_degrees: float) -> PackedVector2Array:
	var steps: int = maxi(1, ceili(deg_to_rad(absf(to_degrees - from_degrees)) * radius / SAMPLE_SPACING))
	var points: PackedVector2Array = []
	for step in steps + 1:
		var angle: float = deg_to_rad(lerpf(from_degrees, to_degrees, float(step) / steps))
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points
