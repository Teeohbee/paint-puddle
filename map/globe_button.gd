class_name GlobeButton
extends Node2D
## "World" with a little globe: drive the pointer onto it and press A to zoom
## back out. The globe turns to face the continent you are in and lights it
## up, so it also says where you are. Drawn from the world screen's own
## outlines, turned back into longitude and latitude.

const BUTTON_RECT: Rect2 = Rect2(1520, 28, 370, 138)
const GLOBE_RADIUS: float = 52.0
const PILL_COLOUR: Color = Color(1.0, 0.97, 0.9, 0.95)
const HOVER_RING_COLOUR: Color = Color(1, 1, 1)
const OCEAN_COLOUR: Color = Color(0.47, 0.72, 0.96)
const LAND_COLOUR: Color = Color(0.91, 0.89, 0.82)
const LIT_LAND_COLOUR: Color = Color(1.0, 0.7, 0.27)
const FONT_SIZE: int = 58
## Every Nth point of an outline is plenty for something this small.
const POINT_STRIDE: int = 3

var continent_id: String = "europe"
var is_hovered: bool = false:
	set(new_value):
		if new_value != is_hovered:
			is_hovered = new_value
			queue_redraw()


func contains(point: Vector2) -> bool:
	return BUTTON_RECT.has_point(point)


func set_continent(new_continent_id: String) -> void:
	continent_id = new_continent_id
	queue_redraw()


func _draw() -> void:
	var pill: StyleBoxFlat = StyleBoxFlat.new()
	pill.bg_color = PILL_COLOUR
	pill.set_corner_radius_all(int(BUTTON_RECT.size.y / 2.0))
	if is_hovered:
		pill.set_border_width_all(8)
		pill.border_color = HOVER_RING_COLOUR
	draw_style_box(pill, BUTTON_RECT)
	var globe_centre: Vector2 = BUTTON_RECT.position + Vector2(80, BUTTON_RECT.size.y / 2.0)
	draw_globe(globe_centre)
	var font: Font = get_tree().root.theme.default_font
	var text_width: float = font.get_string_size("World", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, BUTTON_RECT.position + Vector2(160 + (BUTTON_RECT.size.x - 160 - 24 - text_width) / 2.0, BUTTON_RECT.size.y / 2.0 + FONT_SIZE * 0.34),
		"World", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, PaintColours.INK)


## An orthographic globe turned to face the continent, with its countries lit.
func draw_globe(globe_centre: Vector2) -> void:
	var facing: Vector2 = MapData.longitude_latitude_of(Vector2(MapData.continent(continent_id)["label"][0], MapData.continent(continent_id)["label"][1]))
	var longitude_0: float = deg_to_rad(facing.x)
	var latitude_0: float = deg_to_rad(facing.y)
	draw_circle(globe_centre, GLOBE_RADIUS, OCEAN_COLOUR)
	for country in MapData.world()["countries"]:
		if country["id"] == "antarctica":
			continue
		var colour: Color = LIT_LAND_COLOUR if country["continents"].has(continent_id) else LAND_COLOUR
		for raw_polygon in country["world"]["polygons"]:
			var outline: PackedVector2Array = PackedVector2Array()
			var any_in_view: bool = false
			for point_index in range(0, raw_polygon.size(), POINT_STRIDE):
				var longitude_latitude: Vector2 = MapData.longitude_latitude_of(Vector2(raw_polygon[point_index][0], raw_polygon[point_index][1]))
				var projected: Dictionary = project(longitude_latitude, longitude_0, latitude_0)
				any_in_view = any_in_view or projected["is_visible"]
				outline.append(globe_centre + projected["point"] * GLOBE_RADIUS)
			if any_in_view and outline.size() >= 3 and not Geometry2D.triangulate_polygon(outline).is_empty():
				draw_colored_polygon(outline, colour)
	draw_arc(globe_centre, GLOBE_RADIUS, 0.0, TAU, 48, Color.WHITE, 5.0, true)


## Longitude and latitude (degrees) to a point on the unit disc. Points on the
## far side are pushed out to the rim, which keeps a coastline closed.
static func project(longitude_latitude: Vector2, longitude_0: float, latitude_0: float) -> Dictionary:
	var longitude: float = deg_to_rad(longitude_latitude.x)
	var latitude: float = deg_to_rad(longitude_latitude.y)
	var facing: float = sin(latitude_0) * sin(latitude) + cos(latitude_0) * cos(latitude) * cos(longitude - longitude_0)
	var across: float = cos(latitude) * sin(longitude - longitude_0)
	var up: float = cos(latitude_0) * sin(latitude) - sin(latitude_0) * cos(latitude) * cos(longitude - longitude_0)
	var point: Vector2 = Vector2(across, -up)
	if facing < 0.0 and point.length() > 0.0:
		point = point.normalized()
	return {"point": point, "is_visible": facing > 0.0}
