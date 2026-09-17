extends SceneTree
## Run WITHOUT --headless. Captures actual rendered viewports, never mockups.
const OUT := "res://artifacts/ui_qa/"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT + label + ".png")
	check(result == OK, "Capture saved: " + label)
	print("CAPTURE ", label, " ", Time.get_datetime_string_from_system())

func capture_ratio(label: String, pixels: Vector2i, logical: Vector2i) -> void:
	# Offscreen rendered viewport avoids Windows silently clamping tall windows.
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.size_2d_override = logical
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sample = load("res://scenes/menu.tscn").instantiate()
	viewport.add_child(sample)
	await create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	check(sample.size == Vector2(logical), "Correct logical viewport: " + label)
	check(Rect2(Vector2.ZERO, sample.size).encloses(sample.home_deck.get_node("Play").get_global_rect()), "Play fits: " + label)
	var screenshot := viewport.get_texture().get_image()
	check(screenshot.get_size() == pixels, "Correct capture dimensions: " + label)
	check(screenshot.save_png(OUT + label + ".png") == OK, "Saved: " + label)
	print("CAPTURE ", label, " ", pixels)
	viewport.queue_free()
	await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual QA needs a rendering display; remove --headless.")
		quit(1)
		return
	create_timer(40).timeout.connect(func() -> void: quit(2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(540, 960)
	var profile = root.get_node("Profile")
	var saved: Dictionary = profile.data.duplicate(true)
	profile.data.language = "vi"
	profile.data.reduced = false
	change_scene_to_file("res://scenes/boot.tscn")
	await create_timer(1.0).timeout
	check(current_scene.scene_file_path == "res://scenes/boot.tscn", "Boot shown before transition")
	await capture("intro_anime")
	await create_timer(2.0).timeout
	check(current_scene.scene_file_path == "res://scenes/menu.tscn", "Boot automatically enters menu")
	await capture("menu_anime_9x16")
	var menu = current_scene
	var play: Button = menu.home_deck.get_node("Play")
	check(Rect2(Vector2.ZERO, menu.size).encloses(play.get_global_rect()), "Play is within viewport")
	check(play.size.y >= 96, "Play has a mobile touch target")
	await capture_ratio("menu_anime_9x20", Vector2i(540, 1200), Vector2i(1080, 2400))
	await capture_ratio("menu_anime_3x4", Vector2i(768, 1024), Vector2i(1080, 1440))
	profile.data.language = "en"
	profile.data.reduced = true
	menu.show_home()
	await process_frame
	await capture("menu_anime_en")
	check(menu.home_deck.modulate.a == 1.0, "Reduced motion avoids fade")
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.position = menu.home_deck.get_node("Play").get_global_rect().get_center()
	tap.pressed = true
	root.push_input(tap, true)
	tap = tap.duplicate()
	tap.pressed = false
	root.push_input(tap, true)
	await create_timer(1.0).timeout
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Touching Play enters gameplay")
	# Do not record a run or alter the user's preferences.
	if current_scene.scene_file_path == "res://scenes/main.tscn":
		current_scene.test_mode = true
	await capture("title_to_game")
	profile.data = saved
	current_scene.queue_free()
	await process_frame
	print("TITLE VISUAL/FLOW CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
