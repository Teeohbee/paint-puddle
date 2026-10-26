class_name PaintMixing
extends RefCounted
## How paints mix, like real paint (not light): red and yellow make orange,
## yellow and blue make green, red and blue make purple. Adding a paint
## that's already in the mix changes nothing. Mixing all three makes brown,
## which is what really happens - and the fountain washes it off.

const RAINBOW_ORDER: Array[String] = ["red", "orange", "yellow", "green", "blue", "purple"]

## Which primary paints each colour is made of.
const PRIMARIES_IN: Dictionary = {
	"clean": [],
	"red": ["red"],
	"yellow": ["yellow"],
	"blue": ["blue"],
	"orange": ["red", "yellow"],
	"green": ["yellow", "blue"],
	"purple": ["red", "blue"],
	"brown": ["red", "yellow", "blue"],
}

const COLOURS: Dictionary = {
	"clean": Color(0.97, 0.97, 0.99),
	"red": PaintColours.RED,
	"orange": PaintColours.ORANGE,
	"yellow": PaintColours.YELLOW,
	"green": PaintColours.GREEN,
	"blue": PaintColours.BLUE,
	"purple": PaintColours.PURPLE,
	"brown": Color(0.6, 0.42, 0.28),
}


static func mix(current_paint: String, added_paint: String) -> String:
	var primaries: Array = PRIMARIES_IN[current_paint].duplicate()
	for primary in PRIMARIES_IN[added_paint]:
		if not primaries.has(primary):
			primaries.append(primary)
	return paint_made_of(primaries)


static func paint_made_of(primaries: Array) -> String:
	for paint_name in PRIMARIES_IN:
		if has_same_primaries(PRIMARIES_IN[paint_name], primaries):
			return paint_name
	return "brown"


static func has_same_primaries(first: Array, second: Array) -> bool:
	if first.size() != second.size():
		return false
	for primary in first:
		if not second.has(primary):
			return false
	return true


static func colour_of(paint_name: String) -> Color:
	return COLOURS[paint_name]


static func word_for(paint_name: String) -> String:
	return paint_name.capitalize()
