class_name ClockRungs
extends RefCounted
## The eight rungs of the Clock mode ladder, in the order schools teach them.
## Each rung has its own times, how far one press winds the clock, and how
## the hands and cards look. Rungs are numbered 1 to 8.

const RUNG_COUNT: int = 8

## title: what the rung teaches, on its menu tile.
## minutes_past_the_hour: the times it asks for, in any hour of the day.
## step_minutes: how far one press winds the clock.
const RUNGS: Array[Dictionary] = [
	{"title": "o'clock", "minutes_past_the_hour": [0], "step_minutes": 60},
	{"title": "half past", "minutes_past_the_hour": [30], "step_minutes": 30},
	{"title": "o'clock and half past", "minutes_past_the_hour": [0, 30], "step_minutes": 30},
	{"title": "quarter past", "minutes_past_the_hour": [15], "step_minutes": 15},
	{"title": "quarter to", "minutes_past_the_hour": [45], "step_minutes": 15},
	{"title": "5 past", "minutes_past_the_hour": [5, 10, 20, 25], "step_minutes": 5},
	{"title": "5 to", "minutes_past_the_hour": [35, 40, 50, 55], "step_minutes": 5},
	{"title": "minutes", "minutes_past_the_hour": [], "step_minutes": 1},
]

## The tricky faces, in the order they unlock: one for each rung cleared.
const TRICKY_FACES: Array[String] = [
	"four numbers", "kitchen", "square", "puddle", "marks only", "twin hands", "wristwatch", "bare",
]

## The first rung that shows the minute hand. Below it, only the hour hand is drawn.
const FIRST_RUNG_WITH_THE_MINUTE_HAND: int = 3
## From this rung the hands are just "hour hand" and "minute hand".
const FIRST_RUNG_WITH_SHORT_HAND_NAMES: int = 4
const DIGITAL_HELPER_RUNGS: Array[int] = [4, 5, 6]
const SINGLE_MINUTES_RUNG: int = 8


static func title(rung: int) -> String:
	return RUNGS[rung - 1]["title"]


static func step_minutes(rung: int) -> int:
	return RUNGS[rung - 1]["step_minutes"]


## The minutes past the hour this rung asks for. Rung 8 is every minute
## that isn't on a five.
static func minutes_past_the_hour(rung: int) -> Array[int]:
	var minutes: Array[int] = []
	if rung == SINGLE_MINUTES_RUNG:
		for minute in ClockTime.MINUTES_IN_AN_HOUR:
			if minute % 5 != 0:
				minutes.append(minute)
		return minutes
	minutes.assign(RUNGS[rung - 1]["minutes_past_the_hour"])
	return minutes


## Every time in the 24-hour day this rung can ask for.
static func times_of_the_day(rung: int) -> Array[int]:
	var times: Array[int] = []
	for hour in 24:
		for minute in minutes_past_the_hour(rung):
			times.append(hour * ClockTime.MINUTES_IN_AN_HOUR + minute)
	return times


static func shows_minute_hand(rung: int) -> bool:
	return rung >= FIRST_RUNG_WITH_THE_MINUTE_HAND


static func hour_hand_name(rung: int) -> String:
	if rung >= FIRST_RUNG_WITH_SHORT_HAND_NAMES:
		return "hour hand"
	return "little hour hand"


static func minute_hand_name(rung: int) -> String:
	if rung >= FIRST_RUNG_WITH_SHORT_HAND_NAMES:
		return "minute hand"
	return "big minute hand"


## The small digital time under a card's words, on the rungs where the
## minutes first get tricky. It fades out again after them.
static func shows_digital_helper(rung: int) -> bool:
	return DIGITAL_HELPER_RUNGS.has(rung)


## The tricky faces open for this many rungs cleared.
static func tricky_faces_unlocked(rungs_cleared: int) -> Array[String]:
	var faces: Array[String] = []
	faces.assign(TRICKY_FACES.slice(0, clampi(rungs_cleared, 0, TRICKY_FACES.size())))
	return faces
