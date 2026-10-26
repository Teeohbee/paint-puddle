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
]


static func level_count() -> int:
	return LEVELS.size()


static func is_unlocked(level_index: int) -> bool:
	return level_index <= GameSettings.get_progress("hills_levels_completed")
