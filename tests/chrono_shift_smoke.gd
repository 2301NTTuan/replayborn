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
	game.state = game.State.PLAYING
	game.player.facing = Vector2.RIGHT
	var points_before: int = game.circuit.points.size()
	game.activate_chrono_shift()
	check(game.player.dash_left > 0.0, "Chrono Shift starts a dash")
	check(game.player.dash_cooldown > 6.9, "Chrono Shift starts its cooldown")
	check(game.player.dash_invulnerable, "Chrono Shift grants immediate invulnerability")
	check(game.circuit.points.size() >= points_before + 1, "Chrono Shift creates a Temporal Cut")
	var health_before: float = game.health
	game.take_damage(25)
	check(is_equal_approx(game.health, health_before), "perfect dodge prevents contact damage")
	check(game.chrono_combo >= 18.0, "perfect dodge contributes to combo")
	for tick in range(16):
		game.player.advance(1.0 / 60.0)
	check(game.player.dash_left <= 0.0, "dash resolves safely after its duration")
	check(not game.player.dash_invulnerable, "invulnerability ends with the dash")
	check(not game.player.can_chrono_shift(), "cooldown prevents immediate repeated dash")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("CHRONO SHIFT CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
