extends SceneTree
var failures: int = 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(1409)
	var profile = root.get_node("Profile")
	profile.practice = true
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	await process_frame
	var upgrades: int = 0
	var started: int = Time.get_ticks_msec()
	for tick in range(18000):
		game.damage_time = 99
		game._physics_process(1.0 / 60)
		# Cores are now earned from collected XP, never from a time-based trigger.
		if tick == 1800:
			game.gain_xp(game.xp_to_next)
		if game.state == game.State.UPGRADE:
			game.apply_upgrade(0)
			upgrades += 1
		if tick % 900 == 0:
			await process_frame
	check(game.won and game.state == game.State.ENDED, "practice victory at 300s")
	check(upgrades >= 1, "upgrade flow remains available during the practice run")
	print("Practice simulation ms: ", Time.get_ticks_msec() - started)
	game.queue_free()
	await process_frame
	profile.practice = false
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	game.run_tick = 17999
	game.damage_time = 99
	game._physics_process(1.0 / 60)
	check(is_instance_valid(game.boss), "first boss appears at five minutes")
	var boss = game.boss
	boss.spawn_protection = 0
	boss.skill_primary = 0
	boss.advance(1.0 / 60)
	check(game.combat.hostile.size() >= 8, "boss radial skill fires")
	for level in range(5):
		check(game.boss.spec == game.Catalog.ENEMIES[5 + level], "distinct boss for level %d" % level)
		game.run_tick += 18000
		game.run_time = game.run_tick / 60.0
		game.kill_enemy(game.boss)
		game._physics_process(1.0 / 60)
		if level == 4:
			for death_tick in range(30):
				game._physics_process(1.0 / 60)
			check(game.won, "fifth boss ends the map")
			break
		check(not game.won and not game.director.boss_spawned, "intermediate boss starts next wave")
		var trio: Array = game.map_data.enemies_for_stage(level + 1)
		for index in range(3):
			game.director.spawn_left = 0
			game.director.advance(1.0 / 60)
			check(game.enemies.back().spec == game.Catalog.ENEMIES[trio[index]], "wave cycles through all three types")
		game.run_tick += 18000
		game.damage_time = 99
		game._physics_process(1.0 / 60)
		check(game.enemies.size() == 1 and game.director.boss_spawned, "boss phase clears regular enemies")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RUN CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
