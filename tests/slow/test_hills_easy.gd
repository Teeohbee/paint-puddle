extends HillsSuite
# Rainbow Hills on Easy, played like a child holding right and pressing jump at steps and gaps.

func test_level_1_can_be_finished_just_by_holding_right() -> void:
	var level := await open_level(0)
	check(level.blob.is_on_floor() or level.blob.velocity.y >= 0, "level 1 starts with the blob on the ground")
	await play_through(level, 25.0, false)
	check(level.is_finished, "level 1 (Walk) can be finished just by holding right")
	check(level.word_bar.all_popped(), "walking pops every letter of SUN")
	check(GameSettings.get_progress("hills_levels_completed") == 1, "finishing level 1 unlocks level 2")

func test_level_2_needs_jumping() -> void:
	GameSettings.record_progress("hills_levels_completed", 1)
	var level := await open_level(1)
	await play_through(level, 30.0, false)
	check(not level.is_finished, "level 2 (Hop) needs jumping: holding right alone gets stuck")

# Each level is played with the one before it finished, so finishing it unlocks the next
func test_every_level_can_be_finished_with_good_jumps(level_index: int, test_parameters := [
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12],
	[13],
	[14],
	[15],
	[16],
	[17],
	[18],
	[19],
	[20],
	[21],
	[22],
	[23],
	[24],
	[25],
	[26],
	[27],
	[28],
	[29],
	[30],
	[31],
	[32],
	[33],
	[34],
	[35],
	[36],
	[37],
	[38],
	[39],
]) -> void:
	GameSettings.record_progress("hills_levels_completed", level_index)
	var level := await open_level(level_index)
	var rescues := await play_through(level, 110.0)
	check(level.is_finished, "level %d (%s) can be finished by jumping at steps and gaps" % [level_index + 1, level.level.name])
	check(level.word_bar.all_popped(), "and pops every letter of %s" % level.level.word)
	check(rescues == 0, "%s never needs the cloud with good jumps" % level.level.name)
	check(GameSettings.get_progress("hills_levels_completed") == level_index + 1, "finishing it unlocks the next")

func test_falling_into_a_gap_calls_the_cloud_to_bring_the_blob_back() -> void:
	var level := await open_level(2)
	var blob: Node = level.blob
	Input.action_press("move_right")
	var waited := 0.0
	while not blob.is_being_carried and waited < 8.0:
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	Input.action_release("move_right")
	check(blob.is_being_carried, "falling into a gap calls the cloud")
	await get_tree().create_timer(2.5).timeout
	check(not blob.is_being_carried, "the cloud lets go")
	await get_tree().create_timer(0.5).timeout
	check(level.ground.height_at(blob.position.x) != INF and blob.position.x < 700,
		"and the blob is back on the ground before the gap: x=%.0f" % blob.position.x)
	check(blob.is_on_floor(), "standing on it")
