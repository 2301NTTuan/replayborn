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
	await process_frame
	var drone_core: Resource = load("res://data/upgrades/secondary_drone.tres")
	game.offers = [drone_core]
	game.state = game.State.UPGRADE
	paused = true
	game.hud.show_upgrades(game.offers)
	await process_frame
	game.apply_upgrade(0)
	check(not paused and game.state == game.State.PLAYING, "drone core resumes play")
	check(int(game.secondary_weapons.get("drone")) == 1, "drone core acquired")
	var enemy = game.spawn_enemy(game.Catalog.ENEMIES[0])
	enemy.position = game.player.position + Vector2(220, 0)
	enemy.health = 999.0
	enemy.max_health = 999.0
	enemy.spawn_protection = 0.0
	game.combat.secondary_cooldowns["drone"] = 0.0
	var saw_drone_effect: bool = false
	for frame in range(10):
		game.combat.advance(0.08)
		game.queue_redraw()
		for bullet in game.combat.friendly:
			if String(game.dict_value(bullet, "secondary_id", "")) == "drone":
				saw_drone_effect = true
		for effect in game.combat.effects:
			if bool(game.dict_value(effect, "drone_fire", false)):
				saw_drone_effect = true
		await process_frame
	check(saw_drone_effect, "drone fires readable effects")
	game.combat.friendly.clear()
	game.combat.effects.clear()
	game.combat.enemy_zones.clear()
	game.enemies.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("SECONDARY DRONE CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
