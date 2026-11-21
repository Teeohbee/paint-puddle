class_name MeadowTheme
extends RefCounted
## The colours of the grass, flowers, hedge and bushes. The day is how the
## Meadow has always looked (and the menus, Paint and Write); the evening is
## Meadow Medium's own look, so it feels like a new place. No evening ground
## colour may hide a paint - see test_evening_meadow.

var name: String = "day"
var grass_top: Color = Color(0.6, 0.84, 0.45)
var grass_bottom: Color = Color(0.48, 0.76, 0.38)
var light_patch: Color = Color(0.85, 1.0, 0.6)
var tuft: Color = Color(0.35, 0.62, 0.28, 0.7)
var stem: Color = Color(0.3, 0.55, 0.25)
## Petals are blended towards white by this much (pale flowers in the evening).
var petal_paleness: float = 0.0
var flower_centre: Color = Color(1.0, 0.85, 0.3)
## A warm glow round the edges; clear means none.
var edge_glow: Color = Color(1.0, 0.6, 0.3, 0.0)
var hedge_shadow: Color = Color(0.18, 0.4, 0.2)
var hedge: Color = Color(0.27, 0.55, 0.27)
var hedge_highlight: Color = Color(0.4, 0.7, 0.35, 0.6)
var bush_dark: Color = Color(0.2, 0.45, 0.22)
var bush_mid: Color = Color(0.29, 0.6, 0.3)
var bush_light: Color = Color(0.42, 0.74, 0.38)


static func day() -> MeadowTheme:
	return MeadowTheme.new()


## Deeper blue-green grass, a sunset glow at the edges, pale flowers.
static func evening() -> MeadowTheme:
	var theme: MeadowTheme = MeadowTheme.new()
	theme.name = "evening"
	theme.grass_top = Color(0.2, 0.4, 0.42)
	theme.grass_bottom = Color(0.15, 0.33, 0.37)
	theme.light_patch = Color(0.55, 0.75, 0.7)
	theme.tuft = Color(0.12, 0.27, 0.28, 0.75)
	theme.stem = Color(0.12, 0.3, 0.28)
	theme.petal_paleness = 0.55
	theme.flower_centre = Color(1.0, 0.9, 0.6)
	theme.edge_glow = Color(1.0, 0.55, 0.3, 0.38)
	theme.hedge_shadow = Color(0.06, 0.18, 0.18)
	theme.hedge = Color(0.12, 0.3, 0.27)
	theme.hedge_highlight = Color(0.3, 0.5, 0.42, 0.6)
	theme.bush_dark = Color(0.08, 0.22, 0.2)
	theme.bush_mid = Color(0.13, 0.33, 0.29)
	theme.bush_light = Color(0.26, 0.47, 0.4)
	return theme
