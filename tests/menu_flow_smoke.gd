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
	var original_language: String = profile.data.language
	profile.data.weapon_unlocks = [true, true, true]
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	for page in [menu.show_armory, menu.show_player_upgrades, menu.show_settings, menu.show_help, menu.show_credits, menu.show_home]:
		page.call()
		check(menu.body.get_child_count() > 0, "menu page builds controls")
	profile.data.language = "en"
	menu.show_home()
	check(menu.body.get_child_count() > 0, "English menu rebuilds")
	profile.data.language = original_language
	menu.free()
	await process_frame
	print("MENU FLOW CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
