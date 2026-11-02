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
	},
}


## The scene for a level, falling back to the meadow.
static func scene_for(level: Dictionary) -> Dictionary:
	return SCENES[level.get("scene", DEFAULT_SCENE)]
