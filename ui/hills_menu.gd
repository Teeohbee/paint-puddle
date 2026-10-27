extends MenuScreen
## Pick a Rainbow Hills level. Each one unlocks when the one before it is done.

const LEVEL_TILE_SIZE: Vector2 = Vector2(230, 230)
const LEVELS_PER_ROW: int = 5
const TILE_GAP: int = 30


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Rainbow Hills", 110)
	# Back on the left, then the levels in rows beside it
	var row: HBoxContainer = make_tile_row(300, 50)
	var holder: Control = row.get_parent()
	holder.offset_bottom = 300 + 620
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var level_rows: VBoxContainer = VBoxContainer.new()
	level_rows.add_theme_constant_override("separation", TILE_GAP + 20)
	row.add_child(level_rows)
	var level_row: HBoxContainer = null
	var tile_to_start_on: MenuTile = null
	for level_index in HillsLevels.level_count():
		if level_index % LEVELS_PER_ROW == 0:
			level_row = HBoxContainer.new()
			level_row.add_theme_constant_override("separation", TILE_GAP)
			level_row.alignment = BoxContainer.ALIGNMENT_CENTER
			level_rows.add_child(level_row)
		var level: Dictionary = HillsLevels.LEVELS[level_index]
		var tile: MenuTile = make_tile(level.name, "text:%d" % (level_index + 1), PaintMixing.colour_of(level.paint), LEVEL_TILE_SIZE)
		tile.is_locked = not HillsLevels.is_unlocked(level_index)
		tile.chosen.connect(play_level.bind(level_index))
		level_row.add_child(tile)
		if not tile.is_locked:
			tile_to_start_on = tile
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


func play_level(level_index: int) -> void:
	HillsLevel.level_to_play = level_index
	SceneManager.go_to("res://hills/hills_level.tscn")
