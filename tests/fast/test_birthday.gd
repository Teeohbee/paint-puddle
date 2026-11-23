extends GameSuite
# A birthday file on the machine turns the title into a party: the big one on the day, a smaller one
# for the week after, nothing otherwise. No file, or a broken one, and the title is just the title.

const BirthdayScript = preload("res://core/birthday.gd")
const TitleScreenScript = preload("res://ui/title_screen.gd")

var birthday_path := "user://test_birthday_%d.json" % OS.get_process_id()

func before_test() -> void:
	super()
	BirthdayScript.file_path = birthday_path
	TitleScreenScript.has_cheered_the_birthday = false

func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(birthday_path))
	BirthdayScript.file_path = "user://birthday.json"
	BirthdayScript.today_for_testing = {}
	super()

func write_birthday(contents: String) -> void:
	var file := FileAccess.open(birthday_path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()

func date(year: int, month: int, day: int) -> Dictionary:
	return {"year": year, "month": month, "day": day}

func open_title_on(today: Dictionary):
	BirthdayScript.today_for_testing = today
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
	await get_tree().create_timer(0.3).timeout
	return get_tree().current_scene

func test_the_day_the_week_after_and_the_rest_of_the_year() -> void:
	write_birthday('{"name": "Sam", "born": "2020-03-14"}')
	var birthday = BirthdayScript.load_from_disk()
	check(birthday.party_on(date(2026, 3, 13)) == BirthdayScript.Party.NONE, "the day before: nothing")
	check(birthday.party_on(date(2026, 3, 14)) == BirthdayScript.Party.BIRTHDAY, "the day: a birthday")
	check(birthday.message_on(date(2026, 3, 14)) == "Happy 6th birthday, Sam!", birthday.message_on(date(2026, 3, 14)))
	check(birthday.party_on(date(2026, 3, 15)) == BirthdayScript.Party.BIRTHDAY_WEEK, "the next day: the week")
	check(birthday.party_on(date(2026, 3, 20)) == BirthdayScript.Party.BIRTHDAY_WEEK, "six days on: still the week")
	check(birthday.message_on(date(2026, 3, 20)) == "Sam's birthday week!", birthday.message_on(date(2026, 3, 20)))
	check(birthday.party_on(date(2026, 3, 21)) == BirthdayScript.Party.NONE, "a week on: over")
	check(birthday.age_on(date(2027, 3, 14)) == 7, "and next year they're seven")

func test_a_week_across_new_year_and_a_leap_day_birthday() -> void:
	write_birthday('{"name": "Sam", "born": "2020-12-29"}')
	var birthday = BirthdayScript.load_from_disk()
	check(birthday.party_on(date(2027, 1, 3)) == BirthdayScript.Party.BIRTHDAY_WEEK, "the week carries on into January")
	check(birthday.age_on(date(2027, 1, 3)) == 6, "still the age from December")
	write_birthday('{"name": "Sam", "born": "2020-02-29"}')
	birthday = BirthdayScript.load_from_disk()
	check(birthday.party_on(date(2027, 2, 28)) == BirthdayScript.Party.BIRTHDAY, "29 Feb celebrates on the 28th in other years")
	check(birthday.party_on(date(2028, 2, 29)) == BirthdayScript.Party.BIRTHDAY, "and on the 29th in leap years")

func test_ordinals() -> void:
	var ordinals = [1, 2, 3, 4, 11, 12, 13, 21, 22, 101, 111].map(func(number): return BirthdayScript.ordinal(number))
	check(ordinals == ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd", "101st", "111th"], str(ordinals))

func test_no_file_or_a_broken_one_means_no_birthday() -> void:
	check(BirthdayScript.load_from_disk() == null, "no file")
	for broken in ['not json', '[]', '{"name": "Sam"}', '{"name": "", "born": "2020-03-14"}',
			'{"name": "Sam", "born": "24/11/2021"}', '{"name": "Sam", "born": "2021-13-24"}']:
		write_birthday(broken)
		check(BirthdayScript.load_from_disk() == null, "broken file: " + broken)

func test_the_title_on_the_day() -> void:
	write_birthday('{"name": "Sam", "born": "2020-03-14"}')
	var title = await open_title_on(date(2026, 3, 14))
	check(title.find_children("*", "BirthdayParty", true, false).size() == 1, "balloons and bunting")
	check(title.birthday_message.text == "Happy 6th birthday, Sam!", "the message: " + title.birthday_message.text)
	check(title.find_children("*", "Confetti", true, false).size() == 1, "confetti")
	var looks = title.find_children("*", "PaintBlobLook", true, false)
	check(looks.size() >= 4 and looks.all(func(look): return look.party_hat_colour.a > 0.0), "every blob in a hat")
	title = await open_title_on(date(2026, 3, 14))
	check(title.find_children("*", "Confetti", true, false).size() == 0, "back at the title: no confetti again")
	check(title.birthday_message != null, "but the party's still on")

func test_the_title_in_the_week_and_after() -> void:
	write_birthday('{"name": "Sam", "born": "2020-03-14"}')
	var title = await open_title_on(date(2026, 3, 17))
	check(title.birthday_message.text == "Sam's birthday week!", "the week's message: " + title.birthday_message.text)
	check(title.find_children("*", "Confetti", true, false).size() == 0, "no confetti in the week")
	check(title.find_children("*", "BirthdayParty", true, false)[0].balloon_number == "", "plain balloons in the week")
	title = await open_title_on(date(2026, 3, 21))
	check(title.birthday_message == null, "after the week: no message")
	check(title.find_children("*", "BirthdayParty", true, false).size() == 0, "and no party")
	check(title.find_children("*", "PaintBlobLook", true, false).all(func(look): return look.party_hat_colour.a == 0.0), "and no hats")
