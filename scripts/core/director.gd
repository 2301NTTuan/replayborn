extends RefCounted
const Catalog = preload("res://scripts/data/catalog.gd")
var game: Node
var spawn_left: float = 0.6
var boss_spawned: bool = false
var stage: int = 0
var boss_defeated: int = 0
const LEVEL_COUNT := 5
var level_duration: float = 60.0

func _init(owner_game: Node) -> void:
	game = owner_game

func advance(delta: float) -> void:
	if game.practice:
		stage = mini(5, int(game.run_time / 60.0))
	else:
		stage = mini(LEVEL_COUNT - 1, boss_defeated)
		if game.run_time >= float(boss_defeated + 1) * level_duration and not boss_spawned:
			boss_spawned = true
			game.spawn_enemy(Catalog.ENEMIES[5 + stage], 0, game.map_data.boss_scale * (1.0 + stage * 0.20))
			game.hud.announce("boss_arrives")
	if boss_spawned:
		return
	spawn_left -= delta
	if spawn_left > 0 or game.enemies.size() >= 70:
		return
	var order: Array[int] = game.map_data.enemies_for_stage(stage)
	var data: Resource = Catalog.ENEMIES[order.pick_random()]
	var elite: int = 0
	if game.run_time >= 180 and randf() < 0.13:
		elite = 1 if game.run_time < 300 or randf() < 0.5 else 2
	game.spawn_enemy(data, elite, game.map_data.spawn_scale * (1.0 + stage * 0.22))
	spawn_left = maxf(0.30, 0.92 - stage * 0.10) / game.map_data.spawn_scale

func complete_boss() -> void:
	if not boss_spawned:
		return
	boss_spawned = false
	boss_defeated += 1
	if boss_defeated >= LEVEL_COUNT:
		game.boss_killed = true
	else:
		stage = boss_defeated
		spawn_left = 0.4
		game.hud.announce("level_cleared")
