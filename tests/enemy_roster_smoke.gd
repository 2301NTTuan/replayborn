extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	var ids: Dictionary = {}
	for index in range(5):
		var enemy = game.spawn_enemy(game.Catalog.ENEMIES[index])
		check(not ids.has(enemy.spec.id), "Base enemy families must be distinct")
		ids[enemy.spec.id] = true
		enemy.position = game.player.position + Vector2(100, 0)
		enemy.spawn_protection = 0.0
		enemy.advance(1.0 / 60.0)
		var frames: SpriteFrames = enemy.get_node("ArtVisual").sprite_frames
		for state in ["idle", "run", "windup", "attack", "hurt", "death"]:
			check(frames.has_animation(state) and frames.get_frame_count(state) > 0, "Missing animation " + state)
		game.kill_enemy(enemy)
		var kills: int = game.kills
		game.kill_enemy(enemy)
		check(game.kills == kills, "Death rewards cannot be duplicated")
	check(ids.size() == 5, "Expected five base enemy families")

	var armored = game.spawn_enemy(game.Catalog.ENEMIES[0], 1)
	var volatile = game.spawn_enemy(game.Catalog.ENEMIES[0], 2)
	check(armored.max_health > volatile.max_health, "Armored elite has the larger health modifier")
	check(volatile.speed > armored.speed, "Volatile elite has the speed modifier")

	var boss_textures: Dictionary = {}
	for level in range(5):
		var boss = game.spawn_enemy(game.Catalog.ENEMIES[5 + level])
		var sprite: AnimatedSprite2D = boss.get_node("ArtVisual")
		var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture("idle", 0)
		check(not boss_textures.has(atlas.atlas.resource_path), "Each boss must use its own texture")
		boss_textures[atlas.atlas.resource_path] = true
		for state in ["idle", "run", "windup", "attack", "hurt", "death"]:
			check(sprite.sprite_frames.has_animation(state), "Missing boss animation " + state)
		boss.spawn_protection = 0.0
		boss.skill_primary = 0.3
		boss.advance(1.0 / 60.0)
		game.art.update_enemy(boss)
		check(sprite.animation == &"windup", "Boss animation anticipates skill")
		boss.apply_circuit(PackedVector2Array([boss.position + Vector2(-180, -180), boss.position + Vector2(180, -180), boss.position + Vector2(180, 180), boss.position + Vector2(-180, 180)]))
		boss.time_lock_left = 0.3
		check(boss.circuit_exposed > 0.0 and boss.time_lock_left > 0.0, "Boss accepts circuit vulnerability and reduced lock")
	check(boss_textures.size() == 5, "Expected five unique boss atlases")

	game.queue_free()
	await process_frame
	print("ENEMY ROSTER CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
