class_name DayMoments
extends RefCounted
## What the blob household is doing through the whole 24-hour day, from
## res://data/clock_moments.json. Each moment starts at an hour, or at an
## optional minute past it (its anchor), and lasts until the next one, so any
## time has a moment: 3:40 in the afternoon is still watering the garden.
## Moments are listed in the order they start.
##
## A moment has a name for cards ("Bath time"), what's said when the hands
## land on it by mistake ("That's bath time!"), the room it happens in, what
## the blobs are doing there, and sometimes a meal or a night-time visitor.

const MOMENTS_PATH: String = "res://data/clock_moments.json"
const ROOMS: Array[String] = ["bedroom", "bathroom", "kitchen", "living", "garden"]

static var moments: Array = []


static func all_moments() -> Array:
	if moments.is_empty():
		moments = JSON.parse_string(FileAccess.get_file_as_string(MOMENTS_PATH))
	return moments


## When a moment starts, in minutes of the day: its hour, plus its minute
## when it starts part way through the hour (wake up at 6:30).
static func starts_at(moment: Dictionary) -> int:
	return int(moment["hour"]) * ClockTime.MINUTES_IN_AN_HOUR + int(moment.get("minute", 0))


## The moment going on at this time: the last one to start at or before it.
static func moment_at(minutes_of_the_day: int) -> Dictionary:
	var time: int = ClockTime.wound(minutes_of_the_day, 0)
	var found: Dictionary = all_moments()[all_moments().size() - 1]
	for moment in all_moments():
		if starts_at(moment) <= time:
			found = moment
	return found
