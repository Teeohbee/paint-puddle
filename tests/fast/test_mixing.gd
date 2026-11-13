extends GdUnitTestSuite
# Mixing paint: what each pair of paints makes, in the paint set and the printer set.

func test_paint_mixes(current: String, added: String, expected: String, test_parameters := [
	["clean", "red", "red"],
	["red", "yellow", "orange"],
	["yellow", "red", "orange"],
	["yellow", "blue", "green"],
	["blue", "red", "purple"],
	["red", "red", "red"],
	["orange", "red", "orange"],
	["orange", "yellow", "orange"],
	["green", "blue", "green"],
	["orange", "blue", "brown"],
	["purple", "yellow", "brown"],
	["brown", "red", "brown"],
	# White lightens and black darkens, one step each way
	["clean", "white", "white"],
	["clean", "black", "black"],
	["white", "black", "grey"],
	["black", "white", "grey"],
	["red", "white", "pink"],
	["white", "red", "pink"],
	["pink", "white", "pink"],
	["pink", "black", "red"],
	["red", "black", "dark red"],
	["dark red", "black", "dark red"],
	["dark red", "white", "red"],
	["blue", "white", "sky blue"],
	["blue", "black", "dark blue"],
	["purple", "white", "lilac"],
	["yellow", "white", "lemon"],
	["green", "white", "mint"],
	["orange", "white", "peach"],
	["brown", "white", "light brown"],
	["pink", "blue", "lilac"],
	["dark blue", "yellow", "dark green"],
	["grey", "red", "red"],
	["grey", "white", "white"],
	["grey", "black", "black"],
	["white", "white", "white"],
]) -> void:
	assert_str(PaintMixing.mix(current, added)).is_equal(expected)

func test_printer_mixes(current: String, added: String, expected: String, test_parameters := [
	["clean", "cyan", "cyan"],
	["cyan", "magenta", "blue"],
	["magenta", "yellow", "red"],
	["yellow", "cyan", "green"],
	["blue", "yellow", "black"],
	["red", "cyan", "black"],
	["cyan", "cyan", "cyan"],
	["cyan", "white", "light cyan"],
	["magenta", "black", "dark magenta"],
	["magenta", "white", "light magenta"],
	["red", "white", "pink"],
	["blue", "black", "dark blue"],
	["black", "white", "grey"],
	["clean", "black", "black"],
	["black", "cyan", "dark cyan"],
]) -> void:
	assert_str(PaintMixing.mix(current, added, "printer")).is_equal(expected)

# Printer black from all three inks keeps them, in any order
func test_printer_inks_make_black_in_any_order(order: Array, test_parameters := [
	[["y", "c", "c", "m"]],
	[["y", "m", "c", "c"]],
	[["y", "y", "m", "c"]],
	[["y", "m", "c", "y"]],
	[["c", "m", "y", "m"]],
]) -> void:
	var inks := _inks()
	var bits := 0
	for ink in order:
		bits = PaintMixing.mix_bits(bits, inks[ink])
	assert_str(PaintMixing.paint_made_of(bits, "printer")).is_equal("black")

func test_grey_from_the_inks_plus_cyan_stays_grey() -> void:
	var inks := _inks()
	var grey := PaintMixing.mix_bits(inks.c | inks.m | inks.y, PaintMixing.LIGHT)
	assert_str(PaintMixing.paint_made_of(PaintMixing.mix_bits(grey, inks.c), "printer")).is_equal("grey")

func test_mixing_by_name_and_by_bits_agree() -> void:
	assert_str(PaintMixing.mix("red", "blue")).is_equal(PaintMixing.paint_made_of(PaintMixing.mix_bits(1, 4)))

func test_every_paint_in_every_set_has_a_colour() -> void:
	for colour_set in PaintMixing.COLOUR_SETS:
		for paint_name in PaintMixing.paint_names(colour_set):
			assert_bool(PaintMixing.COLOURS.has(paint_name)) \
				.override_failure_message("%s %s has no colour" % [colour_set, paint_name]).is_true()

func test_paints_that_should_look_different_do() -> void:
	assert_that(PaintMixing.colour_of("pink")).is_not_equal(PaintMixing.colour_of("red"))
	assert_that(PaintMixing.colour_of("dark red")).is_not_equal(PaintMixing.colour_of("red"))
	assert_that(PaintMixing.colour_of("cyan")).is_not_equal(PaintMixing.colour_of("blue"))
	assert_that(PaintMixing.colour_of("magenta")).is_not_equal(PaintMixing.colour_of("purple"))
	var peach := PaintMixing.colour_of("peach")
	var lemon := PaintMixing.colour_of("lemon")
	assert_float(Vector3(peach.r - lemon.r, peach.g - lemon.g, peach.b - lemon.b).length()).is_greater(0.2)

func test_colour_words_read_naturally() -> void:
	assert_str(PaintMixing.word_for("orange")).is_equal("Orange")
	assert_str(PaintMixing.word_for("sky blue")).is_equal("Sky blue")

func test_each_set_has_its_puddles() -> void:
	assert_array(PaintMixing.puddles_for("paint")).is_equal(["red", "yellow", "blue", "white", "black"])
	assert_array(PaintMixing.puddles_for("printer")).is_equal(["cyan", "magenta", "yellow", "white", "black"])

func test_colours_come_from_the_paint_pots() -> void:
	assert_that(PaintMixing.colour_of("green")).is_equal(PaintColours.GREEN)

func test_the_rainbow_has_six_stripes() -> void:
	assert_array(PaintMixing.RAINBOW_ORDER).is_equal(["red", "orange", "yellow", "green", "blue", "purple"])

func _inks() -> Dictionary:
	return {
		"c": PaintMixing.bits_of("cyan", "printer"),
		"m": PaintMixing.bits_of("magenta", "printer"),
		"y": PaintMixing.bits_of("yellow", "printer"),
	}
