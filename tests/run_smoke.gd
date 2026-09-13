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
		if game.state == game.State.UPGRADE:
			game.apply_upgrade(0)
			upgrades += 1
		if tick % 900 == 0:
			await process_frame
	check(game.won and game.state == game.State.ENDED, "practice victory at 300s")
	check(upgrades == 9 and game.echoes.size() == 4, "nine upgrades and echo cap")
	print("Practice simulation ms: ", Time.get_ticks_msec() - started)
	game.queue_free()
	await process_frame
	profile.practice = false
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	game.run_tick = 3599
	game.next_upgrade_tick = 999999
	game.damage_time = 99
	game._physics_process(1.0 / 60)
	check(is_instance_valid(game.boss), "boss appears at ten minutes")
	var boss = game.boss
	boss.spawn_protection = 0
	boss.shot_time = 0
	boss.advance(1.0 / 60)
	check(game.combat.hostile.size() >= 12, "boss radial fire")
	game.director.boss_defeated = 9
	game.kill_enemy(boss)
	game._physics_process(1.0 / 60)
	check(game.won, "boss kill wins")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RUN CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
