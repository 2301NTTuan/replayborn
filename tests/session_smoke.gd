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
	var joystick = game.hud.joystick
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = true
	touch.position = Vector2(150, 1630)
	joystick._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(325, 1630)
	joystick._input(drag)
	check(game.player.touch_direction.x > 0.9 and joystick.center == Vector2(150, 1630), "dynamic touch direction")
	game.toggle_pause()
	check(paused and joystick.finger == -1 and game.player.touch_direction == Vector2.ZERO, "pause clears touch")
	var circuit_points: int = game.circuit.points.size()
	var tick: int = game.run_tick
	await create_timer(0.1).timeout
	check(tick == game.run_tick, "pause freezes simulation")
	check(game.circuit.points.size() == circuit_points, "pause does not record circuit trail")
	game.toggle_pause()
	await create_timer(0.1).timeout
	check(game.run_tick > tick, "resume advances")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused, "focus loss pauses")
	game.toggle_pause()
	game.offer_upgrades()
	circuit_points = game.circuit.points.size()
	game.toggle_pause()
	check(paused and game.state == game.State.UPGRADE, "ESC cannot bypass upgrade")
	check(game.circuit.points.size() == circuit_points, "upgrade overlay does not record trail")
	game.apply_upgrade(0)
	check(not paused, "upgrade selection resumes")
	game.sound.set_levels(0, 0)
	check(game.sound.muted, "mute")
	# Meta progression is deterministic and contains no chest/payment economy.
	var economy = load("res://scripts/core/profile.gd").new()
	economy.save_path = "user://qa_economy_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(economy)
	economy.data.gold = 10000
	economy.data.upgrade_core = 100
	check(economy.upgrade_meta("hp"), "meta upgrade")
	check(economy.data.meta_upgrades.hp == 1, "meta level advances")
	economy.finish_run(true, 600.0, 30, 120, 12, 5)
	check(economy.data.weapon_unlocks[1] and economy.data.weapon_unlocks[2], "gameplay unlocks both weapons")
	economy.free()
	# Test storage with an isolated path; never overwrite the real player profile.
	var store = load("res://scripts/core/profile.gd").new()
	store.save_path = "user://qa_profile_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(store)
	store.data.volume = 0.25
	check(store.save_profile() == OK, "save initial")
	store.data.volume = 0.75
	check(store.save_profile() == OK, "atomic replacement")
	store.load_profile()
	check(is_equal_approx(store.data.volume, 0.75), "reload")
	var corrupt := FileAccess.open(store.save_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	store.load_profile()
	check(is_equal_approx(store.data.volume, 0.25) and store.warning == "save_recovered", "backup recovery")
	store.data = store.defaults()
	store.data.meta_upgrades = {"hp": "bad"}
	store.data.weapon_unlocks = [true, "bad"]
	check(store.save_profile() == OK, "save malformed fixture")
	store.load_profile()
	check(store.data.meta_upgrades.hp is int and store.data.weapon_unlocks[1] is bool, "malformed nested save is sanitized")
	var legacy: Dictionary = store.defaults()
	legacy.version = 1
	legacy.erase("weapon_unlocks")
	var migrated: Dictionary = store.sanitize_profile(store.migrate_profile(legacy))
	check(migrated.version == 2 and migrated.weapon_unlocks.size() == 3, "schema 1 migrates to schema 2")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(store.save_path + suffix):
			DirAccess.remove_absolute(store.save_path + suffix)
	store.free()
	game.free()
	await process_frame
	await create_timer(0.2).timeout
	print("SESSION CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
