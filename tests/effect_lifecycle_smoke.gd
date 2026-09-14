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
	for index in range(game.combat.MAX_EFFECTS + 20):
		game.combat.add_effect({"position": game.player.position + Vector2(index, 0), "life": 0.5})
	check(game.combat.effects.size() <= game.combat.MAX_EFFECTS, "visual effects are capped")
	for index in range(game.combat.MAX_ACTIVE_MINES + 4):
		game.combat.add_effect({"position": game.player.position + Vector2(index * 8, 0), "life": 2.35, "age": 0.0, "mine": true, "armed": false, "detonated": false, "damage": 1.0, "radius": 32.0})
	var active_mines: int = 0
	for effect in game.combat.effects:
		if bool(game.dict_value(effect, "mine", false)) and not bool(game.dict_value(effect, "detonated", false)):
			active_mines += 1
	check(active_mines <= game.combat.MAX_ACTIVE_MINES, "active mines are capped")
	for frame in range(32):
		game.combat.advance(0.1)
		await process_frame
	var remaining_mines: int = 0
	for effect in game.combat.effects:
		if bool(game.dict_value(effect, "mine", false)):
			remaining_mines += 1
	check(remaining_mines == 0, "mines auto-detonate and clear")
	for index in range(game.combat.MAX_ENEMY_ZONES + 12):
		game.combat.add_enemy_zone({"position": game.player.position, "radius": 48.0, "delay": 0.1, "duration": 0.2, "damage": 1, "age": 0.0, "hit": false})
	check(game.combat.enemy_zones.size() <= game.combat.MAX_ENEMY_ZONES, "enemy zones are capped")
	game.combat.friendly.clear()
	game.combat.effects.clear()
	game.combat.enemy_zones.clear()
	game.enemies.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("EFFECT LIFECYCLE CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
