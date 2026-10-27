class_name HillsLevels
extends RefCounted
## The Rainbow Hills levels, each teaching one thing. A level is a list of
## ground pieces read left to right; HillsGround turns it into hills.
##   flat: walk along      slope: walk up or down (rise is negative going up)
##   step: a sudden change in height (negative is up)    gap: a hole to jump

const LEVELS: Array[Dictionary] = [
	{
		"name": "Walk", "word": "SUN", "paint": "yellow",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "slope", "length": 400, "rise": -90},
			{"kind": "flat", "length": 500}, {"kind": "slope", "length": 400, "rise": 90},
			{"kind": "flat", "length": 500}, {"kind": "slope", "length": 300, "rise": -60},
			{"kind": "flat", "length": 700},
		],
	},
	{
		"name": "Hop", "word": "HOP", "paint": "red",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 450}, {"kind": "step", "rise": -60},
			{"kind": "flat", "length": 450}, {"kind": "step", "rise": 60},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": -70},
			{"kind": "flat", "length": 450}, {"kind": "step", "rise": 70},
			{"kind": "flat", "length": 700},
		],
	},
	{
		"name": "Leap", "word": "JUMP", "paint": "blue",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 500}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 450}, {"kind": "gap", "width": 160},
			{"kind": "flat", "length": 450}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 800},
		],
	},
	{
		"name": "Climb", "word": "HILL", "paint": "green",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "step", "rise": -45},
			{"kind": "flat", "length": 260}, {"kind": "step", "rise": -45},
			{"kind": "flat", "length": 260}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 450}, {"kind": "slope", "length": 500, "rise": 140},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 260}, {"kind": "step", "rise": -55},
			{"kind": "flat", "length": 400}, {"kind": "slope", "length": 400, "rise": 105},
			{"kind": "flat", "length": 700},
		],
	},
	{
		"name": "Skip", "word": "FROG", "paint": "orange",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 350}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 350}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 400}, {"kind": "gap", "width": 150},
			{"kind": "flat", "length": 350}, {"kind": "slope", "length": 400, "rise": 100},
			{"kind": "flat", "length": 300}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 350}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 300}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 700},
		],
	},
	{
		"name": "Rainbow", "word": "RAINBOW", "paint": "purple",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "slope", "length": 400, "rise": -90},
			{"kind": "flat", "length": 350}, {"kind": "gap", "width": 130},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 350}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 400}, {"kind": "gap", "width": 150},
			{"kind": "flat", "length": 400}, {"kind": "slope", "length": 500, "rise": 190},
			{"kind": "flat", "length": 350}, {"kind": "step", "rise": -60},
			{"kind": "flat", "length": 350}, {"kind": "gap", "width": 160},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": 60},
			{"kind": "flat", "length": 350}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 400}, {"kind": "slope", "length": 400, "rise": -80},
			{"kind": "flat", "length": 400}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 900},
		],
	},
	{
		"name": "Bumps", "word": "BUMPY", "paint": "red",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "slope", "length": 350, "rise": -80},
			{"kind": "flat", "length": 200}, {"kind": "slope", "length": 350, "rise": 80},
			{"kind": "gap", "width": 120},
			{"kind": "flat", "length": 250}, {"kind": "slope", "length": 350, "rise": -80},
			{"kind": "flat", "length": 200}, {"kind": "slope", "length": 350, "rise": 80},
			{"kind": "gap", "width": 130},
			{"kind": "flat", "length": 250}, {"kind": "slope", "length": 350, "rise": -100},
			{"kind": "flat", "length": 300}, {"kind": "slope", "length": 350, "rise": 100},
			{"kind": "gap", "width": 140},
			{"kind": "flat", "length": 250}, {"kind": "slope", "length": 350, "rise": -80},
			{"kind": "flat", "length": 200}, {"kind": "slope", "length": 350, "rise": 80},
			{"kind": "flat", "length": 700},
		],
	},
	{
		"name": "Tower", "word": "CLOUD", "paint": "blue",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 220}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 220}, {"kind": "step", "rise": -55},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": -55},
			{"kind": "flat", "length": 220}, {"kind": "step", "rise": -60},
			{"kind": "flat", "length": 220}, {"kind": "step", "rise": -60},
			{"kind": "flat", "length": 500}, {"kind": "slope", "length": 500, "rise": 110},
			{"kind": "flat", "length": 250}, {"kind": "slope", "length": 500, "rise": 110},
			{"kind": "flat", "length": 250}, {"kind": "slope", "length": 500, "rise": 110},
			{"kind": "flat", "length": 700},
		],
	},
	{
		# A step down just before a gap makes the far side lower, so it's an easy landing
		"name": "Star", "word": "STAR", "paint": "yellow",
		"pieces": [
			{"kind": "flat", "length": 700}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 300}, {"kind": "step", "rise": -50},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": 50}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 400}, {"kind": "gap", "width": 120},
			{"kind": "flat", "length": 300}, {"kind": "step", "rise": -60},
			{"kind": "flat", "length": 400}, {"kind": "step", "rise": 60}, {"kind": "gap", "width": 160},
			{"kind": "flat", "length": 400}, {"kind": "slope", "length": 400, "rise": -80},
			{"kind": "flat", "length": 350}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 300}, {"kind": "gap", "width": 140},
			{"kind": "flat", "length": 400}, {"kind": "slope", "length": 400, "rise": 80},
			{"kind": "flat", "length": 800},
		],
	},
]


static func level_count() -> int:
	return LEVELS.size()


static func is_unlocked(level_index: int) -> bool:
	return level_index <= GameSettings.get_progress("hills_levels_completed")
