extends RefCounted

const Catalog = preload("res://scripts/data/catalog.gd")
const LEVEL_COUNT := 5

var game: Node
var spawn_left: float = 0.8
var boss_spawned: bool = false
var stage: int = 0
var boss_defeated: int = 0
var level_duration: float = 60.0
var next_horde_at: float = 30.0
var horde_index: int = 0

func _init(owner_game: Node) -> void:
	game = owner_game

func advance(delta: float) -> void:
	if game.practice:
		stage = mini(LEVEL_COUNT, int(game.run_time / 60.0))
	else:
		stage = mini(LEVEL_COUNT - 1, boss_defeated)
		if game.run_time >= float(boss_defeated + 1) * level_duration and not boss_spawned:
			boss_spawned = true
			game.spawn_enemy(Catalog.ENEMIES[5 + stage], 0, game.map_data.boss_scale * (1.0 + stage * 0.20))
			game.hud.announce("boss_arrives")
	if boss_spawned:
		return
	# A horde window starts at 30s and repeats. Between windows the arena breathes.
	if game.run_time >= next_horde_at:
		spawn_horde()
		next_horde_at += maxf(28.0, 44.0 - minf(12.0, game.run_time * 0.018))
		spawn_left = 0.9
		return
	spawn_left -= delta
	if spawn_left > 0 or game.enemies.size() >= 80:
		return
	var order: Array[int] = game.map_data.enemies_for_stage(mini(stage, LEVEL_COUNT - 1))
	if order.is_empty():
		return
	var data: Resource = Catalog.ENEMIES[order.pick_random()]
	var elite: int = 0
	if game.run_time >= 90 and randf() < minf(0.28, 0.07 + game.run_time * 0.0005):
		elite = 1 if randf() < 0.72 else 2
	game.spawn_enemy(data, elite, enemy_difficulty())
	# The opening is deliberately calm, then the single-spawn cadence tightens.
	var cadence := 1.35 - minf(0.58, game.run_time * 0.0017) - stage * 0.04
	spawn_left = maxf(0.38, cadence) / game.map_data.spawn_scale

func spawn_horde() -> void:
	if game.enemies.size() >= 80:
		return
	horde_index += 1
	var order: Array[int] = game.map_data.enemies_for_stage(mini(stage, LEVEL_COUNT - 1))
	if order.is_empty():
		return
	var count := clampi(7 + int(game.run_time / 55.0) + stage * 2, 7, 18)
	var capacity: int = 80 - game.enemies.size()
	count = mini(count, capacity)
	for index in range(count):
		var data: Resource = Catalog.ENEMIES[order[(index + horde_index) % order.size()]]
		var elite := 1 if game.run_time >= 120 and index % 7 == 0 else 0
		if game.run_time >= 240 and index % 11 == 0:
			elite = 2
		game.spawn_enemy(data, elite, enemy_difficulty())

func enemy_difficulty() -> float:
	# Health grows steadily; the cap keeps late practice playable while still dramatic.
	var time_growth := minf(2.65, game.run_time * 0.0065)
	return (1.0 + time_growth + stage * 0.14) * game.map_data.spawn_scale

func complete_boss() -> void:
	if not boss_spawned:
		return
	boss_spawned = false
	boss_defeated += 1
	if boss_defeated >= LEVEL_COUNT:
		game.boss_killed = true
	else:
		stage = boss_defeated
		next_horde_at = maxf(next_horde_at, game.run_time + 12.0)
		spawn_left = 0.4
		game.hud.announce("level_cleared")
