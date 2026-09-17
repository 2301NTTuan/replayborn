extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	var profile = root.get_node("Profile")
	var saved: Dictionary = profile.data.duplicate(true)
	profile.data.reduced = false
	profile.data.language = "vi"
	change_scene_to_file("res://scenes/boot.tscn")
	await create_timer(0.35).timeout
	check(current_scene.scene_file_path == "res://scenes/boot.tscn", "Intro is visible")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(200, 400)
	root.push_input(touch, true)
	await create_timer(0.65).timeout
	check(current_scene.scene_file_path == "res://scenes/menu.tscn", "Touch skips intro")
	if current_scene.scene_file_path == "res://scenes/menu.tscn":
		check(current_scene.home_deck.get_node("Play").has_focus(), "Play has keyboard focus")
	profile.data.reduced = true
	profile.data.language = "en"
	change_scene_to_file("res://scenes/boot.tscn")
	await create_timer(0.9).timeout
	check(current_scene.scene_file_path == "res://scenes/menu.tscn", "Reduced-motion intro ends quickly")
	if current_scene.scene_file_path == "res://scenes/menu.tscn":
		check(current_scene.home_deck.modulate.a == 1.0, "Reduced-motion menu does not animate")
		check(current_scene.home_deck.get_node("Play").text.begins_with("PLAY"), "English Play label")
	profile.data = saved
	current_scene.queue_free()
	await process_frame
	print("TITLE FLOW CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
