extends SceneTree

var failures := 0

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
	var pause: Button = game.hud.pause_button
	check(pause.get_parent() != game.hud.root_control, "pause belongs to the run panel")
	check(pause.size == Vector2(182, 56), "pause matches the memory tile height")
	check(pause.position + pause.size <= pause.get_parent().size, "pause remains inside the run panel")
	check(game.hud.memory_label.get_parent() == pause.get_parent(), "memory indicator shares the run panel")
	game.combat.friendly.clear()
	game.combat.hostile.clear()
	game.combat.effects.clear()
	game.combat.enemy_zones.clear()
	game.enemies.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("HUD LAYOUT CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
