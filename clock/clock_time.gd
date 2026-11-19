class_name ClockTime
extends RefCounted
## The clock's arithmetic. A time is a whole number of minutes since
## midnight, 0 to 1439, so the clock winds through a whole 24-hour day and
## one lap of the face is half of it. Everything here is worked out from that
## one number: where the hands point, how the time is said, and which part of
## the day it is.

const MINUTES_IN_AN_HOUR: int = 60
const MINUTES_IN_A_DAY: int = 24 * 60


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
	var minutes_in_half_a_day: int = MINUTES_IN_A_DAY / 2
	return float(minutes_of_the_day % minutes_in_half_a_day) / minutes_in_half_a_day
