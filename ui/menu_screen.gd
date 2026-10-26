class_name MenuScreen
extends Control
## Shared by every menu: puts the D-pad on the first tile, and if focus ever
## goes missing (a mouse click on nothing, say), puts it back.

var first_focus: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if first_focus != null and get_viewport().gui_get_focus_owner() == null and not SceneManager.is_changing_scene:
		first_focus.grab_focus.call_deferred()


func make_tile(word: String, icon_kind: String, colour: Color, tile_size: Vector2 = Vector2(300, 300)) -> MenuTile:
	var tile: MenuTile = MenuTile.new()
	tile.word = word
	tile.icon_kind = icon_kind
	tile.paint_colour = colour
	tile.custom_minimum_size = tile_size
	return tile


## A row of tiles centred across the screen, with its top at the given height.
func make_tile_row(top: float, gap: int = 70) -> HBoxContainer:
	var holder: CenterContainer = CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = top
	holder.offset_bottom = top + 420
	add_child(holder)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", gap)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.add_child(row)
	return row


func make_heading(text: String, top: float) -> Label:
	var heading: Label = Label.new()
	heading.text = text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.set_anchors_preset(Control.PRESET_TOP_WIDE)
	heading.offset_top = top
	heading.add_theme_font_size_override("font_size", 80)
	heading.add_theme_color_override("font_color", PaintColours.INK)
	heading.add_theme_color_override("font_outline_color", Color.WHITE)
	heading.add_theme_constant_override("outline_size", 26)
	add_child(heading)
	return heading
