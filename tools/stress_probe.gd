extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	# Upgrades are XP-driven; this probe never collects XP.
	for echo_index in range(4):
		game.recorder.begin(game.player.position)
		for tape_tick in range(900):
			game.recorder.record(game.player.position + Vector2(tape_tick % 9, 0), [])
		game.create_echo()
	for index in range(70):
		var enemy = game.spawn_enemy(game.Catalog.ENEMIES[index % 5])
		enemy.health = 1000000
		enemy.max_health = enemy.health
		enemy.spawn_protection = 0
	var samples: Array = []
	for tick in range(360):
		await physics_frame
		while game.combat.friendly.size() < 600:
			game.combat.add_shot({"position": Vector2(randf_range(70, 1010), randf_range(340, 1790)), "velocity": Vector2.RIGHT.rotated(randf() * TAU) * 950, "damage": 0.0, "pierce": 3, "life": 2, "ghost": true, "echo_multiplier": 1.0})
		while game.combat.hostile.size() < 240:
			game.combat.enemy_shot(Vector2(randf_range(70, 1010), randf_range(340, 1790)), Vector2.RIGHT.rotated(randf() * TAU), 250, 0)
		game.damage_time = 99
		var started: int = Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		if tick > 60:
			samples.append(Time.get_ticks_usec() - started)
	samples.sort()
	var report: Dictionary = {"echoes": game.echoes.size(), "enemies": 70, "friendly_cap": 600, "hostile_cap": 240, "median_cpu_us": samples[samples.size() / 2], "p95_cpu_us": samples[int(samples.size() * 0.95)], "max_cpu_us": samples.back(), "static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	print(report)
	var file := FileAccess.open("res://exports/qa/stress.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit()
