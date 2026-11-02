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
		# Two rows of distant hills, far then near
		"far_hills": Color(0.72, 0.86, 0.95),
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
}


## The scene for a level, falling back to the meadow.
static func scene_for(level: Dictionary) -> Dictionary:
	return SCENES[level.get("scene", DEFAULT_SCENE)]
