class_name GameTheme
extends RefCounted
## One theme for every screen: big, chunky, friendly type.

const BODY_FONT_SIZE: int = 52


static func build() -> Theme:
	var theme: Theme = Theme.new()
	var chunky_font: FontVariation = FontVariation.new()
	chunky_font.base_font = ThemeDB.fallback_font
	chunky_font.variation_embolden = 0.9
	chunky_font.spacing_glyph = 2
	theme.default_font = chunky_font
	theme.default_font_size = BODY_FONT_SIZE
	theme.set_color("font_color", "Label", PaintColours.INK)
	theme.set_color("font_outline_color", "Label", Color.WHITE)
	theme.set_constant("outline_size", "Label", 0)
	return theme
