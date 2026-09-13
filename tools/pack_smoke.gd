extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var profile = root.get_node("Profile")
	profile.practice = true
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	for tick in range(18000):
		game.damage_time = 99
		game._physics_process(1.0 / 60)
		if game.state == game.State.UPGRADE:
			game.apply_upgrade(0)
		if tick % 900 == 0:
			await process_frame
	if not game.won:
		push_error("PACKAGED RUN FAILED")
		quit(1)
		return
	print("PACKAGED RUN PASS: 300s practice and packed resources")
	game.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit()
