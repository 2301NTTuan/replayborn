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
	game.sound.set_levels(0, 0)
	game.tutorial_active = true
	game.state = game.State.TUTORIAL
	game.tutorial_last_position = game.player.position
	game.begin_play()
	check(game.state == game.State.PLAYING and game.tutorial_active, "interactive tutorial begins")
	game.player.position += Vector2(180, 0)
	game.advance_tutorial()
	check(game.tutorial_targets_spawned and game.enemies.size() == 4, "movement step spawns four slow targets")
	game.run_tick = 120
	game.run_time = 2.0
	game.kills = 3
	game.finish_tutorial()
	check(not game.tutorial_active and game.state == game.State.PLAYING, "tutorial completes into play")
	check(game.run_tick == 0 and game.kills == 0 and game.enemies.is_empty(), "tutorial state resets before the run")
	game.sound.set_levels(0, 0)
	await create_timer(0.25).timeout
	game.free()
	await process_frame
	await create_timer(0.2).timeout
	print("TUTORIAL CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
