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
