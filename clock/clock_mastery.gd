class_name ClockMastery
extends RefCounted
## When the climbing rung is cleared: 5 cards right first time in a row, on
## two different days. One good afternoon isn't enough - he shows it again
## another day. A miss, or a card answered after help, breaks the run.
##
## The first run of 5 notes its day. After that, only answers on a later day
## build the second run. Days are whole numbers, yyyymmdd, from the caller.

const RUN_TO_MOVE_UP: int = 5

## Cards right first time in a row.
var first_try_run: int = 0
## The day the first run of 5 was made, or 0 before then.
var run_day: int = 0


static func load_saved() -> ClockMastery:
	var mastery: ClockMastery = ClockMastery.new()
	mastery.first_try_run = GameSettings.get_progress("clock_first_try_run")
	mastery.run_day = GameSettings.get_progress("clock_run_day")
	return mastery


func save() -> void:
	GameSettings.record_progress("clock_first_try_run", first_try_run)
	GameSettings.record_progress("clock_run_day", run_day)


## Today on this machine, as yyyymmdd.
static func today() -> int:
	var date: Dictionary = Time.get_date_dict_from_system()
	return date.year * 10000 + date.month * 100 + date.day


## Counts one finished card. Returns true when it clears the rung; the run
## then starts again from nothing, ready for the next rung.
func record_answer(first_try: bool, day: int) -> bool:
	if not first_try:
		first_try_run = 0
		return false
	if run_day == day:
		# Day one's run is in: the same day's answers can't make the second
		return false
	first_try_run += 1
	if first_try_run < RUN_TO_MOVE_UP:
		return false
	first_try_run = 0
	if run_day == 0:
		run_day = day
		return false
	run_day = 0
	return true
