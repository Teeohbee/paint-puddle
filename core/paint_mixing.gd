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
## Paint mode also has printer colours - cyan, magenta and yellow - which
## mix their own way. Each colour set has its own puddles and mixing.
##
## A paint is a handful of bits: one for each primary it holds, plus LIGHT
## and DARK. On paper both shade bits together cancel out, so painting
## black across pink gives red, however many times the blob goes over it.

const RAINBOW_ORDER: Array[String] = ["red", "orange", "yellow", "green", "blue", "purple"]

const LIGHT: int = 8
const DARK: int = 16
const PRIMARY_BITS: int = 7
const SHADE_BITS: int = LIGHT | DARK

## Every paint in each colour set and what it's made of. Paint colours are
## red 1, yellow 2, blue 4; printer colours are cyan 1, magenta 2, yellow 4,
## where all three make black. A few bit patterns have a second name ("also"),
## so names can be shared: printer black is black ink or all three inks.
const COLOUR_SETS: Dictionary = {
	"paint": {
		"puddles": ["red", "yellow", "blue", "white", "black"],
		"paints": {
			"clean": 0,
			"red": 1, "yellow": 2, "blue": 4,
			"orange": 1 | 2, "green": 2 | 4, "purple": 1 | 4, "brown": 1 | 2 | 4,
			"white": LIGHT, "black": DARK, "grey": LIGHT | DARK,
			"pink": 1 | LIGHT, "lemon": 2 | LIGHT, "sky blue": 4 | LIGHT,
			"peach": 1 | 2 | LIGHT, "mint": 2 | 4 | LIGHT, "lilac": 1 | 4 | LIGHT, "light brown": 1 | 2 | 4 | LIGHT,
			"dark red": 1 | DARK, "dark yellow": 2 | DARK, "dark blue": 4 | DARK,
			"dark orange": 1 | 2 | DARK, "dark green": 2 | 4 | DARK, "dark purple": 1 | 4 | DARK, "dark brown": 1 | 2 | 4 | DARK,
		},
		"also": {},
	},
	"printer": {
		"puddles": ["cyan", "magenta", "yellow", "white", "black"],
		"paints": {
			"clean": 0,
			"cyan": 1, "magenta": 2, "yellow": 4,
			"blue": 1 | 2, "red": 2 | 4, "green": 1 | 4,
			"white": LIGHT, "black": DARK, "grey": LIGHT | DARK,
			"light cyan": 1 | LIGHT, "light magenta": 2 | LIGHT, "lemon": 4 | LIGHT,
			"sky blue": 1 | 2 | LIGHT, "pink": 2 | 4 | LIGHT, "mint": 1 | 4 | LIGHT,
			"dark cyan": 1 | DARK, "dark magenta": 2 | DARK, "dark yellow": 4 | DARK,
			"dark blue": 1 | 2 | DARK, "dark red": 2 | 4 | DARK, "dark green": 1 | 4 | DARK,
		},
		"also": {1 | 2 | 4: "black", 1 | 2 | 4 | LIGHT: "grey", 1 | 2 | 4 | DARK: "black"},
	},
}

## What a paint is called on screen, where that's not its name in the code.
## The show's names where it has one for that shade (deep blue, pale yellow),
## ordinary colour names otherwise. The code names stay, so nothing else moves.
const DISPLAY_NAMES: Dictionary = {
	"dark blue": "deep blue", "lemon": "pale yellow",
	"dark orange": "rust", "dark green": "forest green", "dark purple": "plum",
	"dark brown": "chocolate", "light brown": "biscuit",
	"dark cyan": "teal", "dark magenta": "berry", "light cyan": "ice blue", "light magenta": "candy pink",
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
		"cyan": PaintColours.CYAN,
		"magenta": PaintColours.MAGENTA,
	}
	var colours: Dictionary = {
		"clean": Color(0.97, 0.97, 0.99),
		"white": Color(1.0, 1.0, 1.0),
		"grey": Color(0.6, 0.6, 0.64),
		"black": Color(0.18, 0.17, 0.2),
	}
	for colour_set in COLOUR_SETS:
		for paint_name in paint_names(colour_set):
			if colours.has(paint_name):
				continue
			var bits: int = bits_of(paint_name, colour_set)
			var plain_colour: Color = plain_colours[paint_made_of(bits & PRIMARY_BITS, colour_set)]
			if bits & LIGHT:
				colours[paint_name] = plain_colour.lerp(Color.WHITE, LIGHTEN_BY)
			elif bits & DARK:
				colours[paint_name] = plain_colour.darkened(DARKEN_BY)
			else:
				colours[paint_name] = plain_colour
	# Lightened orange came out almost the same as lemon, so peach leans pink
	colours["peach"] = Color(1.0, 0.7, 0.52)
	return colours


static func paint_names(colour_set: String = "paint") -> Array:
	return COLOUR_SETS[colour_set].paints.keys()


static func puddles_for(colour_set: String) -> Array:
	return COLOUR_SETS[colour_set].puddles


static func bits_of(paint_name: String, colour_set: String = "paint") -> int:
	return COLOUR_SETS[colour_set].paints[paint_name]


## Adds one paint to another, as when the blob drives into a puddle: every
## white or black dip counts, up to one step lighter or darker.
static func mix(current_paint: String, added_paint: String, colour_set: String = "paint") -> String:
	var mixed_bits: int = mix_bits(bits_of(current_paint, colour_set), bits_of(added_paint, colour_set))
	return paint_made_of(mixed_bits, colour_set)


## The same mixing on bits. Keep the bits rather than the name when a paint
## will be mixed again: some names stand for more than one paint, like
## printer black, which is either black ink or all three inks together.
static func mix_bits(current_bits: int, added_bits: int) -> int:
	var primaries: int = (current_bits | added_bits) & PRIMARY_BITS
	var shade: int = clampi(shade_of(current_bits) + shade_of(added_bits), -1, 1)
	var has_any_shade: bool = (current_bits | added_bits) & SHADE_BITS != 0
	if primaries == 0 and shade == 0 and has_any_shade:
		return LIGHT | DARK
	var shade_bits: int = LIGHT if shade == 1 else DARK if shade == -1 else 0
	return primaries | shade_bits


## +1 for a light paint, -1 for a dark one, 0 otherwise.
static func shade_of(bits: int) -> int:
	return (1 if bits & LIGHT else 0) - (1 if bits & DARK else 0)


## The paint with these bits. Light and dark together on a colour cancel out.
static func paint_made_of(bits: int, colour_set: String = "paint") -> String:
	if bits & PRIMARY_BITS and bits & SHADE_BITS == SHADE_BITS:
		bits &= PRIMARY_BITS
	if COLOUR_SETS[colour_set].also.has(bits):
		return COLOUR_SETS[colour_set].also[bits]
	return COLOUR_SETS[colour_set].paints.find_key(bits)


static func colour_of(paint_name: String) -> Color:
	return COLOURS[paint_name]


## For sentences and labels: "Deep blue".
static func word_for(paint_name: String) -> String:
	var shown_name: String = DISPLAY_NAMES.get(paint_name, paint_name)
	return shown_name.left(1).to_upper() + shown_name.substr(1)


## A puddle friend's name: "Deep Blue".
static func friend_name_for(paint_name: String) -> String:
	var words: PackedStringArray = DISPLAY_NAMES.get(paint_name, paint_name).split(" ")
	for word_index in words.size():
		words[word_index] = words[word_index].left(1).to_upper() + words[word_index].substr(1)
	return " ".join(words)


## Every paint that can be made, once each: the paint colours first, then
## the printer colours' own. One puddle friend for each.
static func all_friend_paints() -> Array[String]:
	var friends: Array[String] = []
	for colour_set in COLOUR_SETS:
		for paint_name in paint_names(colour_set):
			if paint_name != "clean" and not friends.has(paint_name):
				friends.append(paint_name)
	return friends


## The puddles that make a paint, in the first colour set that has it:
## plum is red + blue + black.
static func recipe_for(paint_name: String) -> Array[String]:
	var recipe: Array[String] = []
	for colour_set in COLOUR_SETS:
		if not paint_names(colour_set).has(paint_name):
			continue
		var bits: int = bits_of(paint_name, colour_set)
		var puddles: Array = puddles_for(colour_set)
		for primary_index in 3:
			if bits & (1 << primary_index):
				recipe.append(puddles[primary_index])
		if bits & LIGHT:
			recipe.append("white")
		if bits & DARK:
			recipe.append("black")
		return recipe
	return recipe
