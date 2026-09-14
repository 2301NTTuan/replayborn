extends SceneTree
var failures := 0

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
	var ids := {}
	for level in range(5):
		for entry in game.map_data.enemies_for_stage(level):
			var enemy = game.spawn_enemy(game.Catalog.ENEMIES[entry])
			check(not ids.has(enemy.spec.id), "Each level must introduce distinct enemies")
			ids[enemy.spec.id] = true
			enemy.position = game.player.position + Vector2(100, 0)
			enemy.spawn_protection = 0
			enemy.shot_time = 0
			enemy.advance(1.0 / 60)
			check(enemy.windup > 0, "Skill must telegraph before attacking")
			var frames: SpriteFrames = enemy.get_node("ArtVisual").sprite_frames
			for state in ["idle", "run", "windup", "attack", "hurt", "death"]:
				check(frames.has_animation(state) and frames.get_frame_count(state) > 0, "Missing animation " + state)
			game.combat.hostile.clear()
			for tick in range(48):
				enemy.advance(1.0 / 60)
			check(not game.combat.hostile.is_empty() or enemy.dash_time > 0 or enemy.attack_hold > 0, "Skill must execute after windup")
			game.kill_enemy(enemy)
			var kills: int = game.kills
			game.kill_enemy(enemy)
			check(game.kills == kills, "Death rewards cannot be duplicated")
			var death_position: Vector2 = enemy.position
			for tick in range(30):
				enemy.advance(1.0 / 60)
			check(enemy.position == death_position and enemy.death_left <= 0, "Death finishes without further movement")
	check(ids.size() == 15, "Expected 15 distinct enemies")
	var boss_textures := {}
	for level in range(5):
		var boss = game.spawn_enemy(game.Catalog.ENEMIES[5 + level])
		var sprite: AnimatedSprite2D = boss.get_node("ArtVisual")
		var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture("idle", 0)
		check(not boss_textures.has(atlas.atlas.resource_path), "Each boss must use its own texture")
		boss_textures[atlas.atlas.resource_path] = true
		for state in ["idle", "run", "windup", "attack", "hurt", "death"]:
			check(sprite.sprite_frames.has_animation(state), "Missing boss animation " + state)
			for frame in range(sprite.sprite_frames.get_frame_count(state)):
				var pose: AtlasTexture = sprite.sprite_frames.get_frame_texture(state, frame)
				check(Rect2(Vector2.ZERO, pose.atlas.get_size()).encloses(pose.region), "Boss frame must be inside atlas")
		boss.spawn_protection = 0
		boss.skill_primary = 0.3
		boss.advance(1.0 / 60)
		game.art.update_enemy(boss)
		check(sprite.animation == &"windup", "Boss animation anticipates skill")
		boss.skill_primary = 0
		boss.advance(1.0 / 60)
		game.art.update_enemy(boss)
		check(sprite.animation == &"attack", "Boss animation matches skill release")
		boss.flash = 0.09
		game.art.update_enemy(boss)
		check(sprite.animation == &"hurt", "Boss has a dedicated hit pose")
		boss.dead = true
		boss.advance(1.0 / 60)
		game.art.update_enemy(boss)
		check(sprite.animation == &"death", "Boss death overrides attack and hurt")
	check(boss_textures.size() == 5, "Expected five unique boss atlases")
	game.queue_free()
	await process_frame
	print("ENEMY ROSTER: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
