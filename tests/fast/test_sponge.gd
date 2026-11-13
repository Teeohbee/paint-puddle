extends GdUnitTestSuite
# The sponge counts the blobs sitting on it, so one leaving doesn't cancel the other's wipe.

func test_one_blob_leaving_keeps_the_other_wiping() -> void:
	var sponge: Node = auto_free(load("res://paint/sponge.gd").new())
	var first_blob: Node2D = auto_free(Node2D.new())
	var second_blob: Node2D = auto_free(Node2D.new())
	sponge.blob_arrived(first_blob)
	sponge.blob_arrived(second_blob)
	sponge.advance(0.5, sponge.is_any_blob_on())
	var before: float = sponge.hold_progress
	sponge.blob_left(first_blob)
	assert_bool(sponge.is_any_blob_on()).override_failure_message("one blob leaving empties the sponge").is_true()
	sponge.advance(0.5, sponge.is_any_blob_on())
	assert_float(sponge.hold_progress).is_greater(before)

func test_leaving_twice_doesnt_go_negative() -> void:
	var sponge: Node = auto_free(load("res://paint/sponge.gd").new())
	var blob: Node2D = auto_free(Node2D.new())
	sponge.blob_arrived(blob)
	sponge.blob_left(blob)
	assert_bool(sponge.is_any_blob_on()).is_false()
	sponge.blob_left(blob)
	assert_bool(sponge.is_any_blob_on()).is_false()
	sponge.blob_arrived(blob)
	assert_bool(sponge.is_any_blob_on()).override_failure_message("a blob arriving after a double leave isn't counted").is_true()
