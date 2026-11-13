extends MenuScreen
## Easy or Medium? Medium stays locked until every Easy level is finished.

const DIFFICULTY_TILE_SIZE: Vector2 = Vector2(320, 320)


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Rainbow Hills", 150)
	var row: HBoxContainer = make_tile_row(400, 60)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	var easy: MenuTile = make_tile("Easy", "hills", PaintColours.GREEN, DIFFICULTY_TILE_SIZE)
	var medium: MenuTile = make_tile("Medium", "hills", PaintColours.ORANGE, DIFFICULTY_TILE_SIZE)
	medium.is_locked = not HillsLevels.is_medium_unlocked()
	for tile in [back, easy, medium]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	easy.chosen.connect(choose_difficulty.bind(HillsLevels.EASY))
	medium.chosen.connect(choose_difficulty.bind(HillsLevels.MEDIUM))
	# Back on the difficulty played last
	var last: String = last_choice("hills_difficulty", HillsLevels.EASY)
	first_focus = medium if last == HillsLevels.MEDIUM and not medium.is_locked else easy
	first_focus.grab_focus_quietly.call_deferred()


func choose_difficulty(difficulty: String) -> void:
	remember_choice("hills_difficulty", difficulty)
	HillsLevel.difficulty = difficulty
	SceneManager.go_to("res://ui/hills_menu.tscn")
