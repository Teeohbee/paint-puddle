extends MenuScreen
## Pick a Rainbow Hills level. Each one unlocks when the one before it is done.

const LEVEL_COLOURS: Array[Color] = [PaintColours.YELLOW, PaintColours.RED, PaintColours.BLUE]


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Rainbow Hills", 150)
	var row: HBoxContainer = make_tile_row(380, 50)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(240, 240))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var tile_to_start_on: MenuTile = null
	for level_index in HillsLevels.level_count():
		var level: Dictionary = HillsLevels.LEVELS[level_index]
		var tile: MenuTile = make_tile(level.name, "text:%d" % (level_index + 1), LEVEL_COLOURS[level_index], Vector2(300, 300))
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile.is_locked = not HillsLevels.is_unlocked(level_index)
		tile.chosen.connect(play_level.bind(level_index))
		row.add_child(tile)
		if not tile.is_locked:
			tile_to_start_on = tile
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


func play_level(level_index: int) -> void:
	HillsLevel.level_to_play = level_index
	SceneManager.go_to("res://hills/hills_level.tscn")
