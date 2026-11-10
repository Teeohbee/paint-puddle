class_name MapTask
extends RefCounted
## One Map mode task card. For now every task is "find": drive the pin to a
## country and press A. Tasks come from data/map_tasks.json, which can be
## edited without touching code.

const TASKS_PATH: String = "res://data/map_tasks.json"
const TYPES: Array[String] = ["find"]

var type: String = "find"
var text: String = ""
## The id of the country that answers it ("france").
var country_id: String = ""
## A picture clue: a drawing from ThingDrawings shown on the card ("kangaroo").
## Empty for plain tasks.
var thing: String = ""


## The tasks in the file, skipping any that name a country the map doesn't have.
static func load_list(path: String = TASKS_PATH) -> Array[MapTask]:
	var tasks: Array[MapTask] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Array:
		push_warning("Map tasks %s couldn't be read" % path)
		return tasks
	for entry in parsed:
		if not entry is Dictionary or not TYPES.has(entry.get("type", "")) or MapData.country(entry.get("country", "")).is_empty():
			push_warning("Skipping a bad map task: %s" % [entry])
			continue
		if entry.get("thing", "") != "" and not ThingDrawings.can_draw(entry["thing"]):
			push_warning("Skipping a map task with a picture we can't draw: %s" % [entry])
			continue
		var task: MapTask = MapTask.new()
		task.thing = entry.get("thing", "")
		task.type = entry["type"]
		task.text = entry.get("text", "")
		task.country_id = entry["country"]
		tasks.append(task)
	return tasks


func country() -> Dictionary:
	return MapData.country(country_id)


func country_name() -> String:
	return country()["name"]


## The continents it can be found from: where it lives, and the other one for
## the few that straddle two.
func continent_ids() -> Array:
	return country()["continents"]
