class_name Birthday
extends RefCounted
## A birthday the title screen celebrates. The name and date of birth live in
## user://birthday.json on the machine that plays the game, never in the repo:
##   {"name": "Sam", "born": "2021-03-14"}
## No file (or a broken one) means no birthday. On the day itself the title
## has a party; for the six days after, a smaller "birthday week".

enum Party { NONE, BIRTHDAY, BIRTHDAY_WEEK }

const SECONDS_PER_DAY: int = 86400
const DAYS_IN_THE_WEEK_AFTER: int = 6

static var file_path: String = "user://birthday.json"
## Tests set this to pretend it's another day: {"year", "month", "day"}.
static var today_for_testing: Dictionary = {}

var name: String = ""
var born_year: int = 0
var born_month: int = 0
var born_day: int = 0


## The birthday from the file, or null when there isn't a usable one.
static func load_from_disk() -> Birthday:
	if not FileAccess.file_exists(file_path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if not parsed is Dictionary or not parsed.get("name") is String or not parsed.get("born") is String:
		push_warning("Birthday: %s isn't {\"name\": ..., \"born\": \"YYYY-MM-DD\"}, so no party" % file_path)
		return null
	var date_parts: PackedStringArray = (parsed.born as String).split("-")
	if date_parts.size() != 3 or not date_parts[0].is_valid_int() or not date_parts[1].is_valid_int() or not date_parts[2].is_valid_int():
		push_warning("Birthday: born should look like 2021-03-14, not %s" % parsed.born)
		return null
	var birthday: Birthday = Birthday.new()
	birthday.name = (parsed.name as String).strip_edges()
	birthday.born_year = date_parts[0].to_int()
	birthday.born_month = date_parts[1].to_int()
	birthday.born_day = date_parts[2].to_int()
	if birthday.name.is_empty() or birthday.born_month < 1 or birthday.born_month > 12 or birthday.born_day < 1 or birthday.born_day > 31:
		push_warning("Birthday: %s has an empty name or an impossible date" % file_path)
		return null
	return birthday


static func today() -> Dictionary:
	if not today_for_testing.is_empty():
		return today_for_testing
	return Time.get_date_dict_from_system()


static func days_between(from_date: Dictionary, to_date: Dictionary) -> int:
	var from_seconds: int = Time.get_unix_time_from_datetime_dict({"year": from_date.year, "month": from_date.month, "day": from_date.day})
	var to_seconds: int = Time.get_unix_time_from_datetime_dict({"year": to_date.year, "month": to_date.month, "day": to_date.day})
	return floori(float(to_seconds - from_seconds) / SECONDS_PER_DAY)


## The birthday in a given year. A 29 February birthday is on the 28th in other years.
func birthday_in(year: int) -> Dictionary:
	var day: int = born_day
	var is_leap_year: bool = (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
	if born_month == 2 and born_day == 29 and not is_leap_year:
		day = 28
	return {"year": year, "month": born_month, "day": day}


## The most recent birthday on or before the date: this year's, or last year's.
func latest_birthday_by(date: Dictionary) -> Dictionary:
	var this_year: Dictionary = birthday_in(date.year)
	if days_between(this_year, date) >= 0:
		return this_year
	return birthday_in(date.year - 1)


func party_on(date: Dictionary) -> Party:
	var days_since: int = days_between(latest_birthday_by(date), date)
	if days_since == 0:
		return Party.BIRTHDAY
	if days_since <= DAYS_IN_THE_WEEK_AFTER:
		return Party.BIRTHDAY_WEEK
	return Party.NONE


## How old they turned on the latest birthday.
func age_on(date: Dictionary) -> int:
	return latest_birthday_by(date).year - born_year


static func ordinal(number: int) -> String:
	var suffix: String = "th"
	if number % 100 < 11 or number % 100 > 13:
		match number % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [number, suffix]


func message_on(date: Dictionary) -> String:
	match party_on(date):
		Party.BIRTHDAY:
			return "Happy %s birthday, %s!" % [ordinal(age_on(date)), name]
		Party.BIRTHDAY_WEEK:
			return "%s's birthday week!" % name
	return ""
