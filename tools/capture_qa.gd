extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/qa/" + label + ".png")

func run() -> void:
	var profile = root.get_node("Profile")
	profile.data.volume = 0
	profile.data.music = 0
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await capture("menu_vi")
	menu.show_settings()
	await capture("settings_vi")
	menu.show_help()
	await capture("help_vi")
	menu.queue_free()
	await process_frame
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	for index in range(5):
		var enemy = game.spawn_enemy(game.Catalog.ENEMIES[index], 0)
		enemy.position = Vector2(200 + index * 160, 750)
		enemy.spawn_protection = 0
	game.circuit.points = PackedVector2Array([Vector2(300, 1200), Vector2(760, 1200), Vector2(760, 1550), Vector2(300, 1550)])
	game.hud.refresh()
	await capture("arena_vi")
	game.toggle_pause()
	await capture("pause_vi")
	game.toggle_pause()
	game.offer_upgrades()
	await capture("upgrades_vi")
	game.apply_upgrade(0)
	game.finish(true)
	await capture("result_vi")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
