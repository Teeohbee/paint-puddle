extends GdUnitTestSuite
# TracingLetters: lowercase letters as dotted strokes, started and drawn the way school teaches them
# (Read Write Inc. Set 1).

const SET_ONE_ORDER: String = "masdtinpgockubfelhrjvywzxq"
const PEN_LIFT_LETTERS: String = "tijfx"
const DOWN_LETTERS: String = "mnprtilhbkuvwxyzj"
const ROUND_LETTERS: String = "acdgoq"

func test_letters_come_in_the_order_school_teaches_them() -> void:
	assert_str(TracingLetters.ORDER).is_equal(SET_ONE_ORDER)

func test_every_letter_has_its_rhyme() -> void:
	for letter in SET_ONE_ORDER:
		assert_str(TracingLetters.rhyme_for(letter)).override_failure_message("%s has no rhyme" % letter).is_not_empty()
	assert_str(TracingLetters.rhyme_for("m")).is_equal("Maisie, mountain, mountain")

func test_pen_lift_letters_have_two_strokes_and_the_rest_one() -> void:
	for letter in SET_ONE_ORDER:
		var expected: int = 2 if PEN_LIFT_LETTERS.contains(letter) else 1
		assert_int(TracingLetters.strokes_for(letter).size()).override_failure_message("%s strokes" % letter).is_equal(expected)

func test_the_dot_on_i_and_j_is_one_dot_above_the_letter() -> void:
	for letter in "ij":
		var strokes: Array = TracingLetters.strokes_for(letter)
		assert_int(strokes[1].size()).is_equal(1)
		assert_float(strokes[1][0].y).override_failure_message("%s dot is above its body" % letter).is_less(_top_of(strokes[0]))

func test_down_letters_start_at_the_top() -> void:
	for letter in DOWN_LETTERS:
		var first_stroke: PackedVector2Array = TracingLetters.strokes_for(letter)[0]
		assert_float(first_stroke[0].y).override_failure_message("%s starts at the top" % letter).is_equal_approx(_top_of(first_stroke), 1.0)

func test_round_letters_start_at_two_o_clock_and_go_anticlockwise() -> void:
	for letter in ROUND_LETTERS:
		var first_stroke: PackedVector2Array = TracingLetters.strokes_for(letter)[0]
		var box: Rect2 = _box_of(first_stroke)
		assert_float(first_stroke[0].x).override_failure_message("%s starts on the right" % letter).is_greater(box.get_center().x)
		var heading: Vector2 = first_stroke[1] - first_stroke[0]
		assert_bool(heading.x < 0.0 and heading.y < 0.0).override_failure_message("%s heads up and left, anticlockwise" % letter).is_true()

func test_e_starts_across_the_middle() -> void:
	var stroke: PackedVector2Array = TracingLetters.strokes_for("e")[0]
	assert_float(stroke[1].x).is_greater(stroke[0].x)
	assert_float(stroke[1].y).is_equal_approx(stroke[0].y, 0.5)

func test_s_and_f_start_on_the_right_of_their_curve() -> void:
	var s_stroke: PackedVector2Array = TracingLetters.strokes_for("s")[0]
	assert_float(s_stroke[0].x).is_greater(_box_of(s_stroke).get_center().x)
	var f_stroke: PackedVector2Array = TracingLetters.strokes_for("f")[0]
	assert_float(f_stroke[0].x).is_greater(f_stroke[f_stroke.size() - 1].x)

func test_every_letter_fits_where_the_blob_can_reach() -> void:
	var area: Rect2 = TracingLetters.PLAY_AREA
	# Inside the hedge (56) by the blob's radius (50), and below the rhyme card
	assert_bool(Rect2(106, 150, 1708, 824).encloses(area)).is_true()
	for letter in SET_ONE_ORDER:
		for stroke in TracingLetters.strokes_for(letter):
			for dot in stroke:
				assert_bool(area.grow(1.0).has_point(dot)).override_failure_message("%s dot %s is outside" % [letter, dot]).is_true()

func test_dots_are_evenly_spaced_with_no_gaps() -> void:
	for letter in SET_ONE_ORDER:
		for stroke in TracingLetters.strokes_for(letter):
			for dot_index in range(1, stroke.size()):
				var gap: float = stroke[dot_index].distance_to(stroke[dot_index - 1])
				assert_float(gap).override_failure_message("%s has a gap of %d" % [letter, gap]).is_less_equal(TracingLetters.DOT_SPACING * 1.5)

func test_letters_are_big_enough_to_steer_round() -> void:
	for letter in SET_ONE_ORDER:
		var box: Rect2 = Rect2()
		for stroke in TracingLetters.strokes_for(letter):
			box = _box_of(stroke) if box.size == Vector2.ZERO else box.merge(_box_of(stroke))
		assert_float(box.size.y).override_failure_message("%s is %d tall" % [letter, box.size.y]).is_greater_equal(400.0)

func _top_of(stroke: PackedVector2Array) -> float:
	return _box_of(stroke).position.y

func _box_of(stroke: PackedVector2Array) -> Rect2:
	var box: Rect2 = Rect2(stroke[0], Vector2.ZERO)
	for dot in stroke:
		box = box.expand(dot)
	return box
