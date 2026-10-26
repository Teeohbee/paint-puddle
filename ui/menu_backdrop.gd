class_name MenuBackdrop
extends Node2D
## The living meadow behind every menu: grass, flowers, cloud shadows and a
## few blobs pottering about.

func _ready() -> void:
	add_child(MeadowGround.new())
	var blobs_layer: Node2D = Node2D.new()
	blobs_layer.y_sort_enabled = true
	add_child(blobs_layer)
	for colour in [PaintColours.YELLOW, PaintColours.BLUE, PaintColours.GREEN]:
		var blob: WanderingBlob = WanderingBlob.new()
		blob.position = Vector2(randf_range(200, 1700), randf_range(500, 900))
		blobs_layer.add_child(blob)
		blob.set_paint_colour(colour)
	add_child(Hedge.new())
	add_child(CloudShadows.new())
