extends GameSuite
# Who is playing is chosen up front on the Play menu and kept across every mode. A pad that disconnects
# leaves its slot waiting for the next A press on a different pad.

var session: Node

func before_test() -> void:
	super()
	session = PlayerSession

func test_it_starts_as_one_player_with_no_devices() -> void:
	assert_bool(session.is_two_player()).is_false()
	assert_array(session.player_devices).is_empty()
	assert_int(session.device_of(0)).override_failure_message("one player has no fixed device").is_equal(-1)

func test_two_different_pads_are_two_players_in_the_order_they_pressed() -> void:
	assert_bool(session.choose_two_players(3, 1)).is_true()
	assert_bool(session.is_two_player()).is_true()
	assert_array([session.device_of(0), session.device_of(1)]).is_equal([3, 1])

func test_bad_pairs_are_refused_and_change_nothing(first: int, second: int, test_parameters := [
	[2, 2],
	[-1, 1],
	[1, -1],
]) -> void:
	assert_bool(session.choose_two_players(first, second)).is_false()
	assert_bool(session.is_two_player()).is_false()
	session.choose_two_players(3, 1)
	assert_bool(session.choose_two_players(first, second)).is_false()
	assert_int(session.device_of(0)).override_failure_message("the old choice should stand").is_equal(3)

func test_going_back_to_one_player_forgets_the_pads() -> void:
	session.choose_two_players(3, 1)
	session.choose_one_player()
	assert_bool(session.is_two_player()).is_false()
	assert_array(session.player_devices).is_empty()

func test_the_join_screen_takes_player_one_then_a_different_player_two() -> void:
	var join: Node = auto_free(load("res://ui/join_screen.gd").new())
	add_child(join)
	await await_idle_frame()
	join.on_pad_pressed(_pad_a(4))
	assert_int(join.first_device).is_equal(4)
	assert_bool(session.is_two_player()).override_failure_message("first A should claim player one only").is_false()
	join.on_pad_pressed(_pad_a(4))
	assert_bool(session.is_two_player()).override_failure_message("the same pad again should do nothing").is_false()
	join.on_pad_pressed(_pad_a(7))
	assert_array(session.player_devices).is_equal([4, 7])

func test_losing_a_pad_that_isnt_playing_changes_nothing() -> void:
	assert_int(session.report_pad_lost(5)).override_failure_message("solo has no slot to lose").is_equal(-1)
	session.choose_two_players(4, 7)
	assert_int(session.report_pad_lost(9)).is_equal(-1)
	assert_bool(session.has_missing_pad()).is_false()

func test_a_lost_pad_leaves_its_slot_for_a_new_pad() -> void:
	var changes := [0]
	session.devices_changed.connect(func(): changes[0] += 1)
	session.choose_two_players(4, 7)
	changes[0] = 0
	assert_int(session.report_pad_lost(7)).is_equal(1)
	assert_bool(session.has_missing_pad()).is_true()
	assert_bool(session.rebind(4)).override_failure_message("player one's own pad can't fill player two's slot").is_false()
	assert_bool(session.rebind(-1)).override_failure_message("nor can the keyboard").is_false()
	assert_bool(session.rebind(2)).is_true()
	assert_array(session.player_devices).is_equal([4, 2])
	assert_bool(session.has_missing_pad()).is_false()
	assert_int(changes[0]).override_failure_message("the modes should be told once").is_equal(1)

func test_with_both_pads_lost_the_first_a_fills_player_one_first() -> void:
	session.choose_two_players(4, 2)
	assert_int(session.report_pad_lost(4)).is_equal(0)
	assert_int(session.report_pad_lost(2)).is_equal(1)
	assert_bool(session.rebind(6)).is_true()
	assert_int(session.device_of(0)).is_equal(6)
	assert_bool(session.has_missing_pad()).is_true()
	assert_bool(session.rebind(8)).is_true()
	assert_int(session.device_of(1)).is_equal(8)
	assert_bool(session.has_missing_pad()).is_false()

func test_the_same_pad_coming_back_fills_its_own_slot() -> void:
	session.choose_two_players(4, 7)
	session.report_pad_lost(7)
	assert_bool(session.rebind(7)).is_true()
	assert_int(session.device_of(1)).is_equal(7)

func test_going_solo_forgets_anyone_missing() -> void:
	session.choose_two_players(4, 7)
	session.report_pad_lost(7)
	session.choose_one_player()
	assert_bool(session.has_missing_pad()).is_false()

func _pad_a(device: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event
