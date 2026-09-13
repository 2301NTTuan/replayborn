extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var profile = root.get_node("Profile")
	profile.practice = false
	var report: Array = []
	for weapon_index in range(3):
		seed(500 + weapon_index)
		profile.selected_weapon = weapon_index
		var game = load("res://scenes/main.tscn").instantiate()
		game.test_mode = true
		root.add_child(game)
		game.set_physics_process(false)
		game.sound.set_levels(0, 0)
		var started: int = Time.get_ticks_usec()
		var maximum: int = 0
		var frames: int = 0
		while game.state != game.State.ENDED and frames < 54001:
			var target := Vector2(540, 1060) + Vector2(cos(frames / 360.0) * 330, sin(frames / 360.0) * 570)
			var steering: Vector2 = game.player.position.direction_to(target)
			for enemy in game.enemies:
				var distance: float = game.player.position.distance_to(enemy.position)
				if distance < 220:
					steering += enemy.position.direction_to(game.player.position) * (1 - distance / 220.0) * 3
			for bullet in game.combat.hostile:
				var distance: float = game.player.position.distance_to(bullet.position)
				if distance < 100:
					steering += (bullet.position as Vector2).direction_to(game.player.position) * (1 - distance / 100.0) * 2
			game.player.touch_direction = steering.limit_length()
			await physics_frame
			var tick_started: int = Time.get_ticks_usec()
			game._physics_process(1.0 / 60)
			maximum = maxi(maximum, Time.get_ticks_usec() - tick_started)
			if game.state == game.State.UPGRADE:
				var pick: int = 0
				for index in range(game.offers.size()):
					if game.offers[index].stat in ["damage", "regen", "pellets", "siphon"]:
						pick = index
				game.apply_upgrade(pick)
			frames += 1
			if frames % 900 == 0:
				await process_frame
		var row: Dictionary = {"weapon": game.weapon.id, "seconds": game.run_time, "won": game.won, "kills": game.kills, "max_tick_us": maximum, "mean_tick_us": (Time.get_ticks_usec() - started) / maxi(1, frames)}
		report.append(row)
		print(row)
		game.queue_free()
		await process_frame
	var output := FileAccess.open("res://exports/qa/balance_probe.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	await create_timer(0.2).timeout
	OS.delay_msec(200)
	quit()


