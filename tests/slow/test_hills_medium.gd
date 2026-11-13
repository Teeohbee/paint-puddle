extends HillsSuite
# Rainbow Hills on Medium: every level can be finished, popping every letter of its longer word, with no
# rescues, and Medium keeps its own progress.

func test_every_medium_level_can_be_finished(level_index: int, test_parameters := [
	[0],
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
	GameSettings.record_progress("hills_levels_completed_medium", level_index)
	var level := await open_level(level_index, HillsLevels.MEDIUM)
	var rescues := await play_through_medium(level, 110.0)
	var word: String = Levels.word_for(level.level, "medium")
	check(level.is_finished, "medium level %d (%s) finished" % [level_index + 1, level.level.name])
	check(level.word_bar.all_popped(), "pops every letter of %s" % word)
	check(rescues == 0, "no rescues")
	check(GameSettings.get_progress("hills_levels_completed_medium") == level_index + 1, "the medium count goes up")
	check(GameSettings.get_progress("hills_levels_completed") == 0, "the easy count is untouched")
