extends SceneTree
var failures: int = 0
var count: int = 0

func _initialize() -> void:
	call_deferred("run")

func scan(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		failures += 1
		return
	for name in directory.get_files():
		if name.get_extension() in ["gd", "tscn", "tres"]:
			count += 1
			if load(path.path_join(name)) == null:
				failures += 1
	for name in directory.get_directories():
		if name not in [".godot", ".git", "exports", "builds"]:
			scan(path.path_join(name))

func run() -> void:
	scan("res://")
	print("RESOURCE VALIDATION: ", count, " files, ", failures, " failures")
	quit(0 if failures == 0 else 1)
