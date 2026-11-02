class_name HillsScenes
extends RefCounted
## How a Rainbow Hills level looks. A level picks a scene with "scene" in
## HillsLevels; a level without one is in the meadow. Scenes only change the
## look - the ground, jumps and balloons are the same everywhere.

const DEFAULT_SCENE: String = "meadow"

const SCENES: Dictionary = {
	"meadow": {
		# The sky: a gradient from top to bottom, with a smiling sun
		"sky_top": Color(0.55, 0.78, 1.0),
		"sky_bottom": Color(0.92, 0.96, 1.0),
		"sky_body": "sun",
		"cloud_colour": Color(1, 1, 1, 0.9),
		# Two rows of distant hills, far then near - or far hills, then the sea
		"far_hills": Color(0.72, 0.86, 0.95),
		"near_layer": "hills",
		"near_hills": Color(0.62, 0.84, 0.6),
		# The ground: soil with pebbles, and a band along the top
		"soil": Color(0.96, 0.83, 0.6),
		"pebbles": Color(0.9, 0.75, 0.52),
		"top_edge": Color(0.3, 0.6, 0.28),
		"top": Color(0.45, 0.78, 0.36),
		# What grows on the ground, and how often, out of 1
		"decorations": [["flower", 0.35], ["tuft", 0.65]],
		"stalks": Color(0.3, 0.55, 0.25),
		"cloud_sea": Color(1, 1, 1, 0.95),
		# Trees along the near hills ("" for none), and weather ("" for none)
		"trees": "",
		"weather": "",
	},
	"snow": {
		"sky_top": Color(0.66, 0.79, 0.92),
		"sky_bottom": Color(0.95, 0.97, 1.0),
		"sky_body": "sun",
		"cloud_colour": Color(1, 1, 1, 0.9),
		"far_hills": Color(0.72, 0.81, 0.93),
		# Bluer than the snow on the ground, so gaps stand out
		"near_layer": "hills",
		"near_hills": Color(0.82, 0.89, 0.98),
		"soil": Color(0.72, 0.76, 0.86),
		"pebbles": Color(0.64, 0.68, 0.79),
		"top_edge": Color(0.74, 0.84, 0.95),
		"top": Color(1, 1, 1),
		"decorations": [["snow tuft", 0.64], ["little pine", 0.28], ["snowman", 0.08]],
		"stalks": Color(0.32, 0.5, 0.5),
		"cloud_sea": Color(0.84, 0.9, 1.0, 0.95),
		"trees": "pines",
		"weather": "snow",
	},
	"autumn": {
		"sky_top": Color(0.62, 0.76, 0.92),
		"sky_bottom": Color(1.0, 0.9, 0.76),
		"sky_body": "sun",
		"cloud_colour": Color(1, 0.98, 0.94, 0.9),
		"far_hills": Color(0.88, 0.74, 0.64),
		"near_layer": "hills",
		"near_hills": Color(0.74, 0.58, 0.42),
		"soil": Color(0.62, 0.44, 0.31),
		"pebbles": Color(0.54, 0.37, 0.26),
		"top_edge": Color(0.62, 0.33, 0.14),
		"top": Color(0.88, 0.53, 0.22),
		"decorations": [["leaf pile", 0.45], ["mushroom", 0.3], ["acorn", 0.25]],
		"stalks": Color(0.45, 0.3, 0.2),
		"cloud_sea": Color(1, 0.97, 0.92, 0.95),
		"trees": "autumn",
		"weather": "leaves",
	},
	"night": {
		"sky_top": Color(0.1, 0.12, 0.3),
		"sky_bottom": Color(0.27, 0.28, 0.52),
		# A sleepy moon, with stars
		"sky_body": "moon",
		"cloud_colour": Color(0.31, 0.34, 0.57),
		"far_hills": Color(0.2, 0.23, 0.42),
		"near_layer": "hills",
		"near_hills": Color(0.16, 0.28, 0.36),
		"soil": Color(0.37, 0.31, 0.38),
		"pebbles": Color(0.31, 0.26, 0.32),
		"top_edge": Color(0.13, 0.32, 0.27),
		"top": Color(0.22, 0.47, 0.35),
		"decorations": [["flower", 0.3], ["tuft", 0.7]],
		"stalks": Color(0.16, 0.36, 0.27),
		"cloud_sea": Color(0.58, 0.62, 0.82, 0.95),
		"trees": "",
		"weather": "fireflies",
	},
	"seaside": {
		"sky_top": Color(0.42, 0.74, 1.0),
		"sky_bottom": Color(0.86, 0.95, 1.0),
		"sky_body": "sun",
		"cloud_colour": Color(1, 1, 1, 0.9),
		"far_hills": Color(0.78, 0.86, 0.72),
		"near_layer": "sea",
		"near_hills": Color(0.28, 0.6, 0.86),
		"soil": Color(0.97, 0.87, 0.64),
		"pebbles": Color(0.92, 0.8, 0.57),
		"top_edge": Color(0.88, 0.75, 0.5),
		"top": Color(1.0, 0.93, 0.72),
		"decorations": [["shell", 0.3], ["starfish", 0.22], ["dune grass", 0.38], ["bucket", 0.1]],
		"stalks": Color(0.5, 0.66, 0.36),
		# Gaps drop into the sea
		"cloud_sea": Color(0.3, 0.62, 0.88, 0.97),
		"trees": "",
		"weather": "gulls",
	},
}

## The colours autumn trees and falling leaves come in.
const AUTUMN_LEAVES: Array[Color] = [Color(0.93, 0.45, 0.2), Color(0.85, 0.28, 0.2), Color(0.96, 0.72, 0.25)]


## The scene for a level, falling back to the meadow.
static func scene_for(level: Dictionary) -> Dictionary:
	return SCENES[level.get("scene", DEFAULT_SCENE)]
