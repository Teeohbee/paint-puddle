class_name SeaLifeData
extends RefCounted
## Where the sea life on the world screen goes, in 1920 x 1080 world-screen
## pixels. Boats sail to and fro along a lane; the whale and dolphins come up
## at a spot now and then. Every point stays well clear of land and names.

enum Kind { SAILING_BOAT, CARGO_SHIP, DINGHY }

## How close any lane or spot may come to land (checked in .tmp_test/sea_life_data_check.gd).
const LAND_CLEARANCE: float = 60.0
## How close a surfacing spot may come to a boat's lane, so the whale never comes up on a boat.
const LANE_CLEARANCE: float = 80.0

## kind, from, to, then colours: hull, and sail / sail 2 (or the two containers).
const LANES: Array[Dictionary] = [
	# Pacific, east side
	{"kind": Kind.SAILING_BOAT, "from": Vector2(60, 360), "to": Vector2(240, 400), "hull": Color("#4a8fe0"), "sail": Color("#ffffff"), "sail_2": Color("#ff9ec0")},
	{"kind": Kind.DINGHY, "from": Vector2(260, 520), "to": Vector2(420, 550), "hull": Color("#ee8a2b"), "sail": Color("#ffffff")},
	{"kind": Kind.SAILING_BOAT, "from": Vector2(110, 700), "to": Vector2(420, 735), "hull": Color("#6bc36e"), "sail": Color("#ffffff"), "sail_2": Color("#ffd45a")},
	{"kind": Kind.CARGO_SHIP, "from": Vector2(130, 820), "to": Vector2(460, 800), "hull": Color("#3b4a7a"), "sail": Color("#ffb347"), "sail_2": Color("#6bc36e")},
	{"kind": Kind.SAILING_BOAT, "from": Vector2(290, 625), "to": Vector2(420, 650), "hull": Color("#ee8a2b"), "sail": Color("#ffffff"), "sail_2": Color("#8a5fc9")},
	# Atlantic
	{"kind": Kind.SAILING_BOAT, "from": Vector2(760, 400), "to": Vector2(800, 310), "hull": Color("#e8524a"), "sail": Color("#ffffff"), "sail_2": Color("#ffd45a")},
	{"kind": Kind.SAILING_BOAT, "from": Vector2(870, 610), "to": Vector2(950, 720), "hull": Color("#e8b922"), "sail": Color("#ffffff"), "sail_2": Color("#e8524a")},
	{"kind": Kind.CARGO_SHIP, "from": Vector2(760, 835), "to": Vector2(1080, 805), "hull": Color("#a63a3a"), "sail": Color("#7fb7e8"), "sail_2": Color("#ffd45a")},
	# Indian Ocean
	{"kind": Kind.CARGO_SHIP, "from": Vector2(1310, 690), "to": Vector2(1460, 720), "hull": Color("#2f7f6f"), "sail": Color("#e8524a"), "sail_2": Color("#ffb347")},
	{"kind": Kind.DINGHY, "from": Vector2(1340, 580), "to": Vector2(1430, 630), "hull": Color("#e8524a"), "sail": Color("#ffffff")},
	{"kind": Kind.SAILING_BOAT, "from": Vector2(1140, 800), "to": Vector2(1440, 800), "hull": Color("#8a5fc9"), "sail": Color("#ffd45a"), "sail_2": Color("#ffffff")},
	# Pacific, by Japan
	{"kind": Kind.SAILING_BOAT, "from": Vector2(1700, 410), "to": Vector2(1860, 380), "hull": Color("#4a8fe0"), "sail": Color("#ffffff"), "sail_2": Color("#ffd45a")},
]

## Where the whale or the dolphins may surface.
const SPOTS: Array[Vector2] = [
	Vector2(190, 300),
	Vector2(70, 480),
	Vector2(50, 870),
	Vector2(490, 690),
	Vector2(670, 360),
	Vector2(820, 720),
	Vector2(1540, 780),
]
