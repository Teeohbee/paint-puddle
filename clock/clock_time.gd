class_name ClockTime
extends RefCounted
## The clock's arithmetic. A time is a whole number of minutes since
## midnight, 0 to 1439, so the clock winds through a whole 24-hour day and
## one lap of the face is half of it. Everything here is worked out from that
## one number: where the hands point, how the time is said, and which part of
## the day it is.

const MINUTES_IN_AN_HOUR: int = 60
const MINUTES_IN_A_DAY: int = 24 * 60
const MINUTES_IN_HALF_A_DAY: int = 12 * 60


## The time after winding the clock on by some minutes (or back, if
## negative). The day wraps round at midnight both ways.
static func wound(minutes_of_the_day: int, minutes_to_wind: int) -> int:
	return posmod(minutes_of_the_day + minutes_to_wind, MINUTES_IN_A_DAY)


## Where the minute hand points, as a fraction of one lap from the 12.
static func minute_hand_turns(minutes_of_the_day: int) -> float:
	return float(minutes_of_the_day % MINUTES_IN_AN_HOUR) / MINUTES_IN_AN_HOUR


## Where the hour hand points, as a fraction of one lap from the 12. It's
## geared to the minute hand, so it creeps between the numbers: at half past
## 3 it sits halfway between the 3 and the 4.
static func hour_hand_turns(minutes_of_the_day: int) -> float:
	return float(minutes_of_the_day % MINUTES_IN_HALF_A_DAY) / MINUTES_IN_HALF_A_DAY


## The time as it's said, with numbers in digits and the rest in words:
## "3 o'clock", "half past 3", "quarter to 4", "10 past 3", "20 to 4",
## "17 minutes past 3". Up to half past it says "past" the hour; after it,
## "to" the next hour.
static func time_words(minutes_of_the_day: int) -> String:
	var minute: int = minutes_of_the_day % MINUTES_IN_AN_HOUR
	var this_hour: int = hour_on_the_face(minutes_of_the_day)
	var next_hour: int = hour_on_the_face(wound(minutes_of_the_day, MINUTES_IN_AN_HOUR))
	if minute == 0:
		return "%d o'clock" % this_hour
	if minute == 30:
		return "half past %d" % this_hour
	if minute == 15:
		return "quarter past %d" % this_hour
	if minute == 45:
		return "quarter to %d" % next_hour
	if minute < 30:
		return "%s past %d" % [minutes_words(minute), this_hour]
	return "%s to %d" % [minutes_words(MINUTES_IN_AN_HOUR - minute), next_hour]


## How many minutes past or to: just the number on a five ("10 past"),
## otherwise with "minutes" ("17 minutes past", "1 minute past").
static func minutes_words(minutes: int) -> String:
	if minutes % 5 == 0:
		return str(minutes)
	if minutes == 1:
		return "1 minute"
	return "%d minutes" % minutes


## The hour the hour hand has reached, as the number on the face: 1 to 12.
static func hour_on_the_face(minutes_of_the_day: int) -> int:
	var hour_of_the_half_day: int = hour_of_the_day(minutes_of_the_day) % 12
	if hour_of_the_half_day == 0:
		return 12
	return hour_of_the_half_day


## The hour of the 24-hour day, 0 to 23, with the minutes dropped.
@warning_ignore("integer_division")
static func hour_of_the_day(minutes_of_the_day: int) -> int:
	return minutes_of_the_day / MINUTES_IN_AN_HOUR
