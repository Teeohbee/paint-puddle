extends GdUnitTestSuite
# TraceProgress: painting a letter's dots in order, a few dots ahead allowed, one stroke at a time.

const REACH: float = 60.0

# Two strokes along y = 0 and y = 500, dots 40 apart: x 0, 40, ... 360
func _two_strokes() -> Array[PackedVector2Array]:
	var first: PackedVector2Array = []
	var second: PackedVector2Array = []
	for dot_index in 10:
		first.append(Vector2(dot_index * 40, 0))
		second.append(Vector2(dot_index * 40, 500))
	return [first, second]

func test_nothing_is_painted_to_begin_with() -> void:
	var progress := TraceProgress.new(_two_strokes())
	assert_int(progress.painted_count()).is_equal(0)
	assert_vector(progress.next_dot()).is_equal(Vector2(0, 0))
	assert_bool(progress.is_finished()).is_false()

func test_far_away_paints_nothing() -> void:
	var progress := TraceProgress.new(_two_strokes())
	assert_int(progress.paint_near(Vector2(0, 300), REACH)).is_equal(0)

func test_the_start_dot_paints_and_the_next_moves_on() -> void:
	var progress := TraceProgress.new(_two_strokes())
	assert_int(progress.paint_near(Vector2(0, 10), REACH)).is_equal(2)
	assert_bool(progress.is_painted(0, 0)).is_true()
	assert_bool(progress.is_painted(0, 1)).is_true()
	assert_vector(progress.next_dot()).is_equal(Vector2(80, 0))

func test_only_a_few_dots_ahead_count() -> void:
	var progress := TraceProgress.new(_two_strokes())
	progress.paint_near(Vector2(80, 0), 200.0)
	assert_int(progress.painted_count()).is_equal(TraceProgress.LOOKAHEAD + 1)

func test_jumping_further_along_paints_nothing() -> void:
	var progress := TraceProgress.new(_two_strokes())
	assert_int(progress.paint_near(Vector2(300, 0), REACH)).is_equal(0)

func test_a_corner_cut_within_the_lookahead_paints_the_dots_skipped() -> void:
	var progress := TraceProgress.new(_two_strokes())
	progress.paint_near(Vector2(0, 0), 30.0)
	assert_int(progress.paint_near(Vector2(120, 0), 30.0)).is_equal(3)
	assert_bool(progress.is_painted(0, 1)).is_true()

func test_the_next_stroke_waits_for_this_one() -> void:
	var progress := TraceProgress.new(_two_strokes())
	assert_int(progress.paint_near(Vector2(0, 500), REACH)).is_equal(0)
	_drive_along(progress, 0)
	assert_int(progress.stroke_index).is_equal(1)
	assert_int(progress.paint_near(Vector2(0, 500), REACH)).is_greater(0)

func test_leaving_the_path_keeps_what_is_painted() -> void:
	var progress := TraceProgress.new(_two_strokes())
	progress.paint_near(Vector2(0, 0), REACH)
	progress.paint_near(Vector2(80, 0), REACH)
	var painted: int = progress.painted_count()
	progress.paint_near(Vector2(900, 900), REACH)
	assert_int(progress.painted_count()).is_equal(painted)

func test_every_stroke_done_finishes_the_letter() -> void:
	var progress := TraceProgress.new(_two_strokes())
	_drive_along(progress, 0)
	_drive_along(progress, 1)
	assert_bool(progress.is_finished()).is_true()
	assert_int(progress.painted_count()).is_equal(20)
	assert_int(progress.paint_near(Vector2(0, 0), REACH)).is_equal(0)

func test_a_one_dot_stroke_paints_and_finishes() -> void:
	var progress := TraceProgress.new([PackedVector2Array([Vector2(5, 5)])])
	progress.paint_near(Vector2(0, 0), REACH)
	assert_bool(progress.is_finished()).is_true()

func test_a_real_letter_can_be_traced_by_following_its_dots() -> void:
	var progress := TraceProgress.new(TracingLetters.strokes_for("t"))
	for stroke in TracingLetters.strokes_for("t"):
		for dot in stroke:
			progress.paint_near(dot, REACH)
	assert_bool(progress.is_finished()).is_true()

func _drive_along(progress: TraceProgress, stroke_index: int) -> void:
	for dot in progress.strokes[stroke_index]:
		progress.paint_near(dot, REACH)
