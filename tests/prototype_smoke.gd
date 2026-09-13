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
	check(game.Catalog.UPGRADES.size() == 15 and game.Catalog.WEAPONS.size() == 3, "content counts")
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
	var recorded_damage: float = shots[0].damage
	game.recorder.begin(Vector2(300, 500))
	for tick in range(900):
		game.recorder.record(Vector2(300 + tick * 0.2, 500), shots if tick == 0 or tick == 899 else [])
	var snapshot: Dictionary = game.recorder.snapshot()
	check(snapshot.positions.size() == 901 and snapshot.shots.size() == 2, "900 ticks including final shot")
	game.create_echo()
	var echo = game.echoes[0]
	game.combat.friendly.clear()
	game.stats.damage = 99
	echo.advance()
	check(game.combat.friendly.size() == 1, "first replay tick fires")
	check(is_equal_approx(game.combat.friendly[0].damage, recorded_damage), "snapshot damage unaffected by later upgrade")
	for tick in range(899):
		echo.advance()
	check(echo.tick == 0 and game.combat.friendly.size() == 2, "final shot plays before wrap")
	echo.advance()
	check(game.combat.friendly.size() == 3, "next loop fires tick zero again")
	for index in range(5):
		game.create_echo()
	check(game.echoes.size() == 4, "echo cap")
	# Sweep test: fast bullets cannot tunnel through a target.
	game.combat.friendly.clear()
	enemy.health = 1
	var projectile: Dictionary = shots[0].duplicate(true)
	projectile.position = Vector2(500, 1050)
	projectile.velocity = Vector2(20000, 0)
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
