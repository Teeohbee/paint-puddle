class_name ContinentScreen
extends MapScreen
## One continent filling the screen, with every country on it. Countries are
## pale until they are found. Countries on two continents (Russia, Turkey,
## Egypt) show on both screens.

const MAGNET_REACH: float = 90.0

var continent_id: String = "europe"


func _ready() -> void:
	var world: Dictionary = MapData.world()
	add_plain_land(MapData.continent(continent_id)["land"])
	for country in world["countries"]:
		if not country["views"].has(continent_id):
			continue
		var view: Dictionary = country["views"][continent_id]
		var label: Vector2 = Vector2(view["label"][0], view["label"][1])
		var shape: MapCountry = MapCountry.make(country["id"], country["name"], MapData.polygons_from(view["polygons"]), label,
			MapData.colour_of(int(country["colour"])))
		shape.is_painted = GameSettings.has_found("countries_found", country["id"])
		add_shape(shape)
		magnets.append(MapMagnet.new(label, MAGNET_REACH, country["id"]))


func paint_country(country_id: String) -> void:
	for shape in shapes:
		if shape.target_id == country_id:
			shape.is_painted = true
