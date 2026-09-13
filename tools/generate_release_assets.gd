extends SceneTree
func _initialize() -> void:
	var icon := Image.new()
	icon.load_svg_from_string(FileAccess.get_file_as_string("res://assets/icon.svg"))
	icon.save_png("res://assets/icon.png")
	var notice := FileAccess.open("res://assets/THIRD_PARTY_NOTICES.txt", FileAccess.WRITE)
	notice.store_string("Replayborn uses Godot Engine. Game visuals and synthesized audio are generated within this project.\n\n")
	notice.store_string(Engine.get_license_text() + "\n\n")
	for info in Engine.get_copyright_info():
		notice.store_string(str(info) + "\n\n")
	for name in Engine.get_license_info():
		notice.store_string(name + "\n" + Engine.get_license_info()[name] + "\n\n")
	notice.close()
	quit()
