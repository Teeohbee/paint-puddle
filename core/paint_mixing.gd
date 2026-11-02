class_name PaintMixing
extends RefCounted
## How paints mix, like real paint (not light): red and yellow make orange,
## yellow and blue make green, red and blue make purple. Adding a paint
## that's already in the mix changes nothing. Mixing all three makes brown,
## which is what really happens - and the fountain washes it off.
##
## White makes a paint one step lighter and black one step darker: red and
## white make pink, pink and black go back to red. White and black on their
## own make grey.
##
## A paint is a handful of bits: one for each primary it holds, plus LIGHT
## and DARK. On paper both shade bits together cancel out, so painting
## black across pink gives red, however many times the blob goes over it.

const RAINBOW_ORDER: Array[String] = ["red", "orange", "yellow", "green", "blue", "purple"]

const LIGHT: int = 8
const DARK: int = 16
const PRIMARY_BITS: int = 7
const SHADE_BITS: int = LIGHT | DARK

## Every paint and what it's made of. The primaries are red 1, yellow 2, blue 4.
const PAINT_BITS: Dictionary = {
	"clean": 0,
	"red": 1, "yellow": 2, "blue": 4,
	"orange": 1 | 2, "green": 2 | 4, "purple": 1 | 4, "brown": 1 | 2 | 4,
	"white": LIGHT, "black": DARK, "grey": LIGHT | DARK,
	"pink": 1 | LIGHT, "lemon": 2 | LIGHT, "sky blue": 4 | LIGHT,
	"peach": 1 | 2 | LIGHT, "mint": 2 | 4 | LIGHT, "lilac": 1 | 4 | LIGHT, "light brown": 1 | 2 | 4 | LIGHT,
	"dark red": 1 | DARK, "dark yellow": 2 | DARK, "dark blue": 4 | DARK,
	"dark orange": 1 | 2 | DARK, "dark green": 2 | 4 | DARK, "dark purple": 1 | 4 | DARK, "dark brown": 1 | 2 | 4 | DARK,
}

## How far white lightens a paint and black darkens it.
const LIGHTEN_BY: float = 0.55
const DARKEN_BY: float = 0.45

static var COLOURS: Dictionary = make_colours()


static func make_colours() -> Dictionary:
	var plain_colours: Dictionary = {
		"red": PaintColours.RED,
		"orange": PaintColours.ORANGE,
		"yellow": PaintColours.YELLOW,
		"green": PaintColours.GREEN,
		"blue": PaintColours.BLUE,
		"purple": PaintColours.PURPLE,
		"brown": Color(0.6, 0.42, 0.28),
	}
	var colours: Dictionary = {
		"clean": Color(0.97, 0.97, 0.99),
		"white": Color(1.0, 1.0, 1.0),
		"grey": Color(0.6, 0.6, 0.64),
		"black": Color(0.18, 0.17, 0.2),
	}
	for paint_name in PAINT_BITS:
		if colours.has(paint_name):
			continue
		var bits: int = PAINT_BITS[paint_name]
		var plain_colour: Color = plain_colours[paint_made_of(bits & PRIMARY_BITS)]
		if bits & LIGHT:
			colours[paint_name] = plain_colour.lerp(Color.WHITE, LIGHTEN_BY)
		elif bits & DARK:
			colours[paint_name] = plain_colour.darkened(DARKEN_BY)
		else:
			colours[paint_name] = plain_colour
	return colours


static func paint_names() -> Array:
	return PAINT_BITS.keys()


static func bits_of(paint_name: String) -> int:
	return PAINT_BITS[paint_name]


## Adds one paint to another, as when the blob drives into a puddle: every
## white or black dip counts, up to one step lighter or darker.
static func mix(current_paint: String, added_paint: String) -> String:
	var current_bits: int = bits_of(current_paint)
	var added_bits: int = bits_of(added_paint)
	var primaries: int = (current_bits | added_bits) & PRIMARY_BITS
	var shade: int = clampi(shade_of(current_bits) + shade_of(added_bits), -1, 1)
	var has_any_shade: bool = (current_bits | added_bits) & SHADE_BITS != 0
	if primaries == 0 and shade == 0 and has_any_shade:
		return "grey"
	var shade_bits: int = LIGHT if shade == 1 else DARK if shade == -1 else 0
	return paint_made_of(primaries | shade_bits)


## +1 for a light paint, -1 for a dark one, 0 otherwise.
static func shade_of(bits: int) -> int:
	return (1 if bits & LIGHT else 0) - (1 if bits & DARK else 0)


## The paint with these bits. Light and dark together on a colour cancel out.
static func paint_made_of(bits: int) -> String:
	if bits & PRIMARY_BITS and bits & SHADE_BITS == SHADE_BITS:
		bits &= PRIMARY_BITS
	return PAINT_BITS.find_key(bits)


static func colour_of(paint_name: String) -> Color:
	return COLOURS[paint_name]


static func word_for(paint_name: String) -> String:
	return paint_name.left(1).to_upper() + paint_name.substr(1)
