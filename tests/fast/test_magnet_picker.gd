extends GdUnitTestSuite
# Which puddle, pot or fountain pulls the meadow blob in when the D-pad is let go.

class FakeMagnet:
	var global_position: Vector2
	var magnet_radius := 100.0
	func _init(at: Vector2) -> void:
		global_position = at

var puddle := FakeMagnet.new(Vector2(0, 0))
var pot := FakeMagnet.new(Vector2(500, 0))
var magnets := [puddle, pot]

func test_standing_still_near_a_puddle_drifts_onto_it() -> void:
	assert_object(MagnetPicker.new().pick(Vector2(60, 0), magnets)).is_same(puddle)

func test_away_from_everything_nothing_pulls() -> void:
	assert_object(MagnetPicker.new().pick(Vector2(300, 0), magnets)).is_null()

func test_letting_go_while_heading_at_a_puddle_drifts_onto_it() -> void:
	var picker := MagnetPicker.new()
	picker.note_steering(Vector2(-80, 0), Vector2(1, 0), magnets)
	assert_object(picker.pick(Vector2(-80, 0), magnets)).is_same(puddle)

func test_tapping_away_from_a_puddle_isnt_dragged_back() -> void:
	var picker := MagnetPicker.new()
	picker.note_steering(Vector2(0, 0), Vector2(0, -1), magnets)
	picker.note_steering(Vector2(0, -40), Vector2(0, -1), magnets)
	assert_object(picker.pick(Vector2(0, -50), magnets)).is_null()
	assert_object(picker.pick(Vector2(0, -50), magnets)).override_failure_message("even once the blob has stopped").is_null()
	picker.note_steering(Vector2(0, -50), Vector2(1, 0), magnets)
	assert_object(picker.pick(Vector2(20, -60), magnets)).override_failure_message("nor after a tap sideways").is_null()
	assert_object(picker.pick(Vector2(0, -150), magnets)).override_failure_message("out of reach, nothing pulls").is_null()
	assert_object(picker.pick(Vector2(0, -80), magnets)) \
		.override_failure_message("once it has left and come back still, the puddle pulls again").is_same(puddle)

func test_letting_go_just_past_a_puddle_doesnt_pull_back_onto_it() -> void:
	var picker := MagnetPicker.new()
	picker.note_steering(Vector2(-90, 10), Vector2(1, 0), magnets)
	picker.note_steering(Vector2(50, 10), Vector2(1, 0), magnets)
	assert_object(picker.pick(Vector2(60, 10), magnets)).is_null()

func test_heading_from_a_puddle_towards_a_pot_picks_the_pot() -> void:
	var near_pot := FakeMagnet.new(Vector2(150, 0))
	var picker := MagnetPicker.new()
	picker.note_steering(Vector2(70, 0), Vector2(1, 0), [puddle, near_pot])
	assert_object(picker.pick(Vector2(75, 0), [puddle, near_pot])).is_same(near_pot)
