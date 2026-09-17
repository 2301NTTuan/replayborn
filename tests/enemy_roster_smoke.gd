extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var catalog = load("res://scripts/data/catalog.gd")
	var regular_ids: Dictionary = {}
	var used_ids: Dictionary = {}
	var visual_regions: Dictionary = {}
	for enemy_data in catalog.REGULAR_ENEMIES:
		var id := String(enemy_data.id)
		check(not id.is_empty() and not regular_ids.has(id), "Regular enemy ID must be unique: " + id)
		check(catalog.regular_enemy_by_id(id) == enemy_data, "Regular enemy lookup must be stable: " + id)
		check(not enemy_data.allowed_levels.is_empty(), "Enemy needs allowed levels: " + id)
		regular_ids[id] = true
	for level_data in catalog.LEVELS:
		check(not level_data.enemy_ids.is_empty(), "Level needs an enemy roster: " + String(level_data.id))
		check(catalog.map_by_id(String(level_data.map_id)) != null, "Level map ID resolves: " + String(level_data.map_id))
		check(catalog.boss_by_id(String(level_data.boss_id)) != null, "Level boss ID resolves: " + String(level_data.boss_id))
		for enemy_id in level_data.enemy_ids:
			check(catalog.regular_enemy_by_id(enemy_id) != null, "Level enemy ID resolves: " + enemy_id)
			used_ids[enemy_id] = true
	for id in regular_ids:
		check(used_ids.has(id), "Every regular enemy appears in a level: " + id)

	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_levels(0, 0)
	for enemy_data in catalog.REGULAR_ENEMIES:
		var enemy = game.spawn_enemy(enemy_data)
		enemy.spawn_protection = 0.0
		var sprite: AnimatedSprite2D = enemy.get_node("ArtVisual")
		var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture("idle", 0)
		var signature := "%s:%s" % [atlas.atlas.resource_path, atlas.region]
		check(not visual_regions.has(signature), "Regular families must not share an identical frame region")
		visual_regions[signature] = true
		for state in ["idle", "run", "windup", "attack", "hurt", "death"]:
			check(sprite.sprite_frames.has_animation(state), "Missing animation " + state + " for " + String(enemy_data.id))
		game.kill_enemy(enemy)
	check(visual_regions.size() == catalog.REGULAR_ENEMIES.size(), "All regular family visuals are distinct")
	for boss_data in catalog.BOSSES:
		check(not regular_ids.has(String(boss_data.id)), "Boss cannot appear in regular pool")
		check(catalog.boss_by_id(String(boss_data.id)) == boss_data, "Boss lookup must be stable")
	game.sound.set_levels(0, 0)
	game.free()
	await process_frame
	await create_timer(0.25).timeout
	print("ENEMY ROSTER CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
