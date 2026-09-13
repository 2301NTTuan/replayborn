extends RefCounted
const Catalog = preload("res://scripts/data/catalog.gd")
var game: Node
var spawn_left: float = 0.6
var boss_spawned: bool = false
var stage: int = 0

func _init(owner_game: Node) -> void:
	game = owner_game

func advance(delta: float) -> void:
	stage = mini(5, int(game.run_time / 120))
	if not game.practice and game.run_time >= 600 and not boss_spawned:
		boss_spawned = true
		game.spawn_enemy(Catalog.ENEMIES[5], 0, 1.0)
		game.hud.announce("boss_arrives")
	spawn_left -= delta
	if spawn_left > 0 or game.enemies.size() >= 70:
		return
	var available: int = mini(5, 1 + int(game.run_time / 45))
	var data: Resource = Catalog.ENEMIES[randi_range(0, available - 1)]
	var elite: int = 0
	if game.run_time >= 180 and randf() < 0.13:
		elite = 1 if game.run_time < 300 or randf() < 0.5 else 2
	game.spawn_enemy(data, elite, 1.0 + minf(game.run_time, 600) / 500.0)
	spawn_left = maxf(0.30, 0.95 - game.run_time / 1000.0)
	if boss_spawned:
		spawn_left = 1.2
