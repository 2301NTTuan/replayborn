extends SceneTree

var failures: int = 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var profile = root.get_node("Profile")
	profile.practice = true
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.sound.set_levels(0, 0)
	var polygon := PackedVector2Array([Vector2(200, 600), Vector2(880, 600), Vector2(880, 1450), Vector2(200, 1450)])
	for weapon_index in range(3):
		game.weapon = game.Catalog.WEAPONS[weapon_index]
		var targets: Array = []
		for index in range(4):
			var enemy = game.spawn_enemy(game.Catalog.REGULAR_ENEMIES[index % game.Catalog.REGULAR_ENEMIES.size()])
			enemy.position = Vector2(330 + index * 120, 920 + index * 55)
			enemy.spawn_protection = 0.0
			enemy.health = 1000.0
			enemy.max_health = 1000.0
			targets.append(enemy)
		var before: float = targets[0].health
		var result: Dictionary = game.circuit_finisher.apply(game, game.weapon, polygon, targets)
		check(result.hits > 0 and targets[0].health < before, "%s finisher damages captured targets" % game.weapon.id)
		check(targets[0].time_lock_left > 0.0, "%s applies time lock" % game.weapon.id)
		for target in targets:
			game.enemies.erase(target)
			target.queue_free()
	var sequence_target = game.spawn_enemy(game.Catalog.regular_enemy_by_id("ruby_beetle"))
	sequence_target.position = Vector2(520, 920)
	sequence_target.spawn_protection = 0.0
	sequence_target.health = 1000.0
	sequence_target.max_health = 1000.0
	var queued: Dictionary = game.circuit_finisher.begin(game, game.weapon, polygon, [sequence_target])
	check(bool(queued.queued) and game.circuit_finisher.phase_name() == "lock", "live Circuit starts in the lock phase")
	var sequence_before: float = sequence_target.health
	var impact: Dictionary = game.circuit_finisher.advance(game, 0.11)
	check(impact.hits > 0 and sequence_target.health < sequence_before, "Circuit applies damage at the finisher impact")
	game.circuit_finisher.advance(game, 0.19)
	game.circuit_finisher.advance(game, 0.17)
	check(game.circuit_finisher.phase_name() == "idle", "Circuit releases safely after its finisher")
	game.enemies.erase(sequence_target)
	sequence_target.queue_free()
	var boss = game.spawn_enemy(game.Catalog.boss_by_id("boss_warden"))
	boss.position = Vector2(540, 1000)
	boss.spawn_protection = 0.0
	boss.health = 1000.0
	boss.max_health = 1000.0
	game.weapon = game.Catalog.WEAPONS[0]
	game.circuit_finisher.apply(game, game.weapon, polygon, [boss])
	check(boss.circuit_exposed > 0.0 and boss.time_lock_left > 0.0, "boss receives reduced lock and circuit vulnerability")
	game.enemies.clear()
	boss.queue_free()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("CIRCUIT FINISHER CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
