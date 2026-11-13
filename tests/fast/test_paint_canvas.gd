extends GdUnitTestSuite
# The paint canvas: trails, splats, and two brushes keeping their own pass state, so paint mixes once per
# pass and never with itself.

const Canvas = preload("res://paint/paint_canvas.gd")
const CENTRE := Vector2(600, 500)

func test_a_trail_paints_along_its_line() -> void:
	var paper := _paper()
	paper.paint_line(Vector2(200, 300), Vector2(600, 300), _bits("blue"))
	assert_str(paper.paint_at(Vector2(400, 300))).is_equal("blue")

func test_a_splat_is_a_big_dab_plus_droplets() -> void:
	var paper := _paper()
	paper.splat(CENTRE, _bits("blue"))
	assert_str(paper.paint_at(CENTRE)).is_equal("blue")
	assert_str(paper.paint_at(CENTRE + Vector2(60, 0))).override_failure_message("a splat should be bigger than a trail dab").is_equal("blue")
	assert_int(paper.cells.count(0)).override_failure_message("droplets should add paint beyond the main blob") \
		.is_less(paper.cells.size() - 1400)

func test_the_same_splat_always_looks_the_same() -> void:
	var first := _paper()
	var second := _paper()
	first.splat(CENTRE, _bits("blue"))
	second.splat(CENTRE, _bits("blue"))
	assert_array(second.cells).is_equal(first.cells)

# The main blob and its droplets don't mix with each other, only with what was there
func test_splat_on_splat_mixes_once() -> void:
	var paper := _paper()
	paper.splat(CENTRE, _bits("blue"))
	paper.splat(CENTRE, _bits("red"))
	assert_str(paper.paint_at(CENTRE)).is_equal("purple")
	var other := _paper()
	other.splat(CENTRE, _bits("red"))
	other.splat(CENTRE, _bits("yellow"))
	assert_str(other.paint_at(CENTRE)).is_equal("orange")

func test_a_splat_at_the_corners_of_the_paper_is_fine() -> void:
	var paper := _paper()
	paper.splat(Vector2(2, 2), _bits("red"))
	paper.splat(Vector2(1918, 1078), _bits("red"))
	assert_str(paper.paint_at(Vector2(2, 2))).is_equal("red")

func test_a_resting_brush_mixes_its_square_once_while_the_other_brush_paints() -> void:
	var paper := _paper()
	paper.paint_line(Vector2(200, 300), Vector2(300, 300), _bits("yellow"), 0)
	for frame in 30:
		paper.paint_line(Vector2(300, 300), Vector2(300, 300), _bits("blue"), 0)
		paper.paint_line(Vector2(1000 + frame, 700), Vector2(1001 + frame, 700), _bits("red"), 1)
	assert_str(paper.paint_at(Vector2(300, 300))).is_equal("green")

func test_one_brush_crossing_the_others_trail_mixes_once() -> void:
	var paper := _paper()
	paper.paint_line(Vector2(200, 300), Vector2(300, 300), _bits("yellow"), 0)
	paper.paint_line(Vector2(1800, 40), Vector2(1800, 40), _bits("red"), 1)
	paper.paint_line(Vector2(250, 200), Vector2(250, 400), _bits("red"), 1)
	paper.paint_line(Vector2(250, 400), Vector2(250, 450), _bits("red"), 1)
	assert_str(paper.paint_at(Vector2(250, 300))).is_equal("orange")

func test_one_brush_painting_over_its_own_pass_doesnt_remix() -> void:
	var paper := _paper()
	paper.paint_line(Vector2(200, 300), Vector2(600, 300), _bits("blue"))
	paper.paint_line(Vector2(400, 300), Vector2(400, 300), _bits("red"))
	assert_str(paper.paint_at(Vector2(250, 300))).is_equal("blue")

func _paper() -> Node2D:
	var paper: Node2D = Canvas.new()
	add_child(paper)
	return auto_free(paper)

func _bits(paint_name: String) -> int:
	return PaintMixing.bits_of(paint_name, "paint")
