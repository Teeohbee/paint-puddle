extends GdUnitTestSuite
# Two scripts with the same class_name make Godot pick one of them for both, which silently broke the
# Meadow's rainbow pots once. Every name in the game is unique.

func test_every_class_name_is_used_once() -> void:
	var owners := {}
	for path in _scripts_in("res://", []):
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("class_name "):
				var name := line.substr(11).strip_edges()
				owners[name] = owners.get(name, []) + [path]
	assert_int(owners.size()).is_greater(50)
	var clashes := owners.keys().filter(func(name): return owners[name].size() > 1)
	assert_array(clashes).override_failure_message("class_names used twice: %s" %
		[clashes.map(func(name): return "%s %s" % [name, owners[name]])]).is_empty()

# The game's own scripts: hidden folders and the installed addons aren't ours
func _scripts_in(folder: String, found: Array) -> Array:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		if not sub.begins_with(".") and folder.path_join(sub) != "res://addons":
			_scripts_in(folder.path_join(sub), found)
	return found
