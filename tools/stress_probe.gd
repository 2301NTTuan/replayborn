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
	for index in range(79):
		var enemy = game.spawn_enemy(game.Catalog.REGULAR_ENEMIES[index % game.Catalog.REGULAR_ENEMIES.size()])
		enemy.health = 1000000
		enemy.max_health = enemy.health
		enemy.spawn_protection = 0
	var boss = game.spawn_enemy(game.Catalog.boss_by_id("boss_archon"))
	boss.position = Vector2(540, 1000)
	boss.spawn_protection = 0.0
	boss.health = 1000000.0
	boss.max_health = boss.health
	boss.skill_primary = 0.0
	boss.skill_secondary = 0.0
	boss.skill_tertiary = 0.0
	for index in range(game.MAX_XP_ORBS):
		game.spawn_xp_orb(Vector2(randf_range(80, 1000), randf_range(360, 1780)), 1)
	for index in range(game.MAX_GOLD_ORBS):
		game.spawn_gold_orb(Vector2(randf_range(80, 1000), randf_range(360, 1780)), 1)
	var samples: Array = []
	for tick in range(360):
		await physics_frame
		while game.combat.friendly.size() < game.combat.MAX_FRIENDLY:
			game.combat.add_shot({"position": Vector2(randf_range(70, 1010), randf_range(340, 1790)), "velocity": Vector2.RIGHT.rotated(randf() * TAU) * 950, "damage": 0.0, "pierce": 3, "life": 2, "ghost": true})
		while game.combat.hostile.size() < game.combat.MAX_HOSTILE:
			game.combat.enemy_shot(Vector2(randf_range(70, 1010), randf_range(340, 1790)), Vector2.RIGHT.rotated(randf() * TAU), 250, 0)
		game.damage_time = 99
		var started: int = Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		if tick > 60:
			samples.append(Time.get_ticks_usec() - started)
	samples.sort()
	var polygon := PackedVector2Array([Vector2(80, 360), Vector2(1000, 360), Vector2(1000, 1780), Vector2(80, 1780)])
	var captured: Array = game.circuit.select_targets(polygon, game.enemies)
	game.weapon = game.Catalog.WEAPONS[1]
	game.stats.scatter_shrapnel = 1
	game.resolve_circuit({"polygon": polygon, "targets": captured})
	var report: Dictionary = {"enemies": game.enemies.size(), "xp_orbs": game.xp_orbs.size(), "gold_orbs": game.gold_orbs.size(), "friendly_cap": game.combat.MAX_FRIENDLY, "hostile_cap": game.combat.MAX_HOSTILE, "circuit_targets": captured.size(), "median_cpu_us": samples[samples.size() / 2], "p95_cpu_us": samples[int(samples.size() * 0.95)], "max_cpu_us": samples.back(), "static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	print(report)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://exports/qa"))
	var file := FileAccess.open("res://exports/qa/stress.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit()
