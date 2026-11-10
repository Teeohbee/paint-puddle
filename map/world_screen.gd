class_name WorldScreen
extends MapScreen
## The whole world on one screen: seven continents, each in its own colour.
## Drive onto one and press A to zoom in. Russia is split where Europe
## becomes Asia, so Europe isn't a stripe right across the top.

const NAME_FONT_SIZE: int = 44
const BORDER_COLOUR: Color = Color(1, 1, 1, 0.8)
const BORDER_WIDTH: float = 1.5

var continent_labels: Array[Dictionary] = []


func _ready() -> void:
	var world: Dictionary = MapData.world()
	add_plain_land(world["world_land"])
	var colour_of_continent: Dictionary = {}
	for continent in world["continents"]:
		colour_of_continent[continent["id"]] = MapData.colour_of(int(continent["colour"]))
		continent_labels.append({"name": continent["name"], "position": Vector2(continent["label"][0], continent["label"][1])})
	for country in world["countries"]:
		var pieces: Array[PackedVector2Array] = MapData.polygons_from(country["world"]["polygons"])
		var label: Vector2 = Vector2(country["world"]["label"][0], country["world"]["label"][1])
		if world["world_split"].has(country["id"]):
			add_split_country(country, pieces, label, float(world["world_split"][country["id"]]), colour_of_continent)
		else:
			add_world_shape(country["home"], pieces, label, colour_of_continent[country["home"]])
	var names: ContinentNames = ContinentNames.new()
	names.labels = continent_labels
	add_child(names)


func add_world_shape(continent_id: String, pieces: Array[PackedVector2Array], label: Vector2, colour: Color) -> void:
	var shape: MapCountry = MapCountry.make(continent_id, MapData.continent(continent_id)["name"], pieces, label, colour)
	shape.washes_when_unpainted = false
	shape.rings_when_highlighted = false
	shape.outline_colour = BORDER_COLOUR
	shape.outline_width = BORDER_WIDTH
	shape.refresh_look()
	add_shape(shape)


## A country that straddles two continents: the part west of the split keeps
## its home colour, the rest takes the other continent's.
func add_split_country(country: Dictionary, pieces: Array[PackedVector2Array], label: Vector2, split_x: float, colour_of_continent: Dictionary) -> void:
	var west_of_split: PackedVector2Array = PackedVector2Array([Vector2(-2000, -2000), Vector2(split_x, -2000), Vector2(split_x, 3000), Vector2(-2000, 3000)])
	var east_of_split: PackedVector2Array = PackedVector2Array([Vector2(split_x, -2000), Vector2(4000, -2000), Vector2(4000, 3000), Vector2(split_x, 3000)])
	var home_id: String = country["home"]
	var other_id: String = country["continents"][1]
	var west: Array[PackedVector2Array] = []
	var east: Array[PackedVector2Array] = []
	for piece in pieces:
		west.append_array(Geometry2D.intersect_polygons(piece, west_of_split))
		east.append_array(Geometry2D.intersect_polygons(piece, east_of_split))
	if not west.is_empty():
		add_world_shape(home_id, west, label, colour_of_continent[home_id])
	if not east.is_empty():
		add_world_shape(other_id, east, label, colour_of_continent[other_id])


## Continent names, on a layer of their own so they sit above every shape.
class ContinentNames:
	extends Node2D

	var labels: Array[Dictionary] = []

	func _draw() -> void:
		var font: Font = get_tree().root.theme.default_font
		for label in labels:
			var text: String = label["name"]
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
			var baseline: Vector2 = label["position"] + Vector2(-width / 2.0, NAME_FONT_SIZE * 0.35)
			draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, NAME_FONT_SIZE / 4, Color.WHITE)
			draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, PaintColours.INK)
