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
	profile.data.weapon = 0
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	check(game.Catalog.UPGRADES.size() == 18 and game.Catalog.WEAPONS.size() == 3 and game.Catalog.MAPS.size() == 1, "content counts")
	check(game.map_data == game.Catalog.MAPS[0], "vertical slice locks Neon Ruins")
	game.sound.set_levels(0, 0)
	game.director.spawn_left = INF
	var before: Vector2 = game.player.position
	Input.action_press("move_right")
	game._physics_process(1.0 / 60)
	Input.action_release("move_right")
	check(game.player.position.x > before.x, "WASD movement")
	game.player.position = Vector2(-100, 9999)
	game.player.advance(1.0 / 60)
	check(game.ARENA.has_point(game.player.position), "arena clamp")
	game.player.position = Vector2(540, 1050)
	var enemy = game.spawn_enemy(game.Catalog.ENEMIES[0])
	enemy.position = Vector2(640, 1050)
	enemy.spawn_protection = 0
	check(game.nearest_enemy() == enemy, "nearest target")
	game.combat.fire_left = 0
	var shots: Array = game.combat.fire(enemy, 1.0 / 60)
	check(shots.size() == 1, "pulse single shot")
	check(game.circuit.points.size() >= 1 and game.circuits_closed == 0, "time circuit starts with one sampled point")
	# Sweep test: fast bullets cannot tunnel through a target.
	game.combat.friendly.clear()
	enemy.health = 1
	var projectile: Dictionary = shots[0].duplicate(true)
	projectile.position = Vector2(500, 1050)
	projectile.velocity = Vector2(20000, 0)
	projectile.damage = enemy.health
	game.combat.add_shot(projectile)
	game.combat.advance(1.0 / 60)
	check(enemy.dead, "swept projectile hit")
	game.health = 100
	game.take_damage(10)
	game.take_damage(10)
	check(game.health == 90, "contact grace")
	game.state = game.State.UPGRADE
	game.offers = [game.Catalog.UPGRADES[0]]
	game.apply_upgrade(-1)
	check(game.state == game.State.UPGRADE, "invalid upgrade rejected")
	game.apply_upgrade(0)
	check(game.state == game.State.PLAYING, "upgrade resumes")
	game.finish(false)
	check(game.state == game.State.ENDED and game.hud.overlay.visible, "result")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PROTOTYPE CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
