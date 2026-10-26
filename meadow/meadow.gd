extends Node2D
## The meadow: grass, a hedge all round, a few bushes to steer round and the
## blob. Bushes and blob share a y-sorted layer so the blob can go behind them.

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
const BUSH_LAYOUT: Array[Dictionary] = [
	{"position": Vector2(520, 700), "radius": 72.0, "berries": Color(0.9, 0.25, 0.4)},
	{"position": Vector2(1380, 760), "radius": 84.0, "berries": Color(0.35, 0.45, 0.95)},
	{"position": Vector2(960, 860), "radius": 58.0, "berries": Color(1.0, 0.8, 0.2)},
	{"position": Vector2(300, 330), "radius": 60.0, "berries": Color(0.65, 0.4, 0.9)},
	{"position": Vector2(1640, 340), "radius": 66.0, "berries": Color(0.9, 0.25, 0.4)},
]

var blob: MeadowBlob


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	add_child(MeadowGround.new())
	var trail: PaintTrail = PaintTrail.new()
	add_child(trail)
	var things_on_the_grass: Node2D = Node2D.new()
	things_on_the_grass.name = "ThingsOnTheGrass"
	things_on_the_grass.y_sort_enabled = true
	add_child(things_on_the_grass)
	for bush_details in BUSH_LAYOUT:
		var bush: Bush = Bush.new()
		bush.position = bush_details.position
		bush.radius = bush_details.radius
		bush.berry_colour = bush_details.berries
		things_on_the_grass.add_child(bush)
	blob = BLOB_SCENE.instantiate()
	blob.position = Vector2(960, 540)
	things_on_the_grass.add_child(blob)
	trail.follow(blob)
	blob.bumped_into_something.connect(func(): Sound.play("bump"))
	add_child(Hedge.new())
	add_child(CloudShadows.new())
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
