extends RefCounted

const Catalog = preload("res://scripts/data/catalog.gd")
const LEVEL_COUNT := 5
const MAX_ACTIVE_ENEMIES: int = 76

var game: Node
var spawn_left: float = 0.8
var boss_spawned: bool = false
var stage: int = 0
var boss_defeated: int = 0
const PHASE_DURATION := 47.5
const LEVEL_DURATION := 95.0
var level_duration: float = LEVEL_DURATION
var next_horde_at: float = 18.0
var horde_index: int = 0
var level_started_at: float = 0.0
var spawn_index: int = 0
var transition_left: float = 0.0

func _init(owner_game: Node) -> void:
	game = owner_game

func advance(delta: float) -> void:
	if transition_left > 0.0:
		transition_left = maxf(0.0, transition_left - delta)
		if transition_left <= 0.0 and boss_defeated < LEVEL_COUNT:
			boss_spawned = false
			stage = boss_defeated
			level_started_at = game.run_time
			next_horde_at = game.run_time + 18.0
			spawn_index = 0
			spawn_left = 2.0
		return
	if game.practice:
		stage = mini(LEVEL_COUNT, int(game.run_time / 60.0))
	else:
		stage = mini(LEVEL_COUNT - 1, boss_defeated)
		if boss_defeated >= LEVEL_COUNT:
			return
		var level_data: Resource = Catalog.LEVELS[stage]
		if game.run_time - level_started_at >= level_data.duration and not boss_spawned:
			boss_spawned = true
			# End the wave before the duel; no leftover swarm during the boss.
			for enemy in game.enemies:
				enemy.queue_free()
			game.enemies.clear()
			game.combat.hostile.clear()
			game.spawn_enemy(Catalog.ENEMIES[level_data.boss_index], 0, game.map_data.boss_scale * (1.0 + stage * 0.20))
			game.hud.announce("boss_arrives")
			game.feedback(12.0, 55)
	if boss_spawned:
		return
	# A horde window starts at 30s and repeats. Between windows the arena breathes.
	if game.run_time >= next_horde_at:
		spawn_horde()
		next_horde_at += maxf(28.0, 44.0 - minf(12.0, game.run_time * 0.018))
		spawn_left = 0.9
		return
	spawn_left -= delta
	if spawn_left > 0 or game.enemies.size() >= MAX_ACTIVE_ENEMIES:
		return
	var order: Array[int] = Catalog.LEVELS[mini(stage, LEVEL_COUNT - 1)].enemy_indices
	if order.is_empty():
		return
	var data: Resource = Catalog.ENEMIES[order[spawn_index % order.size()]]
	spawn_index += 1
	var phase_time: float = game.run_time - level_started_at
	var hard_phase: bool = phase_time >= PHASE_DURATION
	var elite: int = 0
	if hard_phase and randf() < float(Catalog.LEVELS[stage].elite_chance):
		elite = 1 if randf() < 0.72 else 2
	game.spawn_enemy(data, elite, enemy_difficulty())
	# The opening is deliberately calm, then the single-spawn cadence tightens.
	var cadence := 1.30 if not hard_phase else 0.88
	spawn_left = cadence / game.map_data.spawn_scale

func spawn_horde() -> void:
	if game.enemies.size() >= MAX_ACTIVE_ENEMIES:
		return
	horde_index += 1
	var order: Array[int] = Catalog.LEVELS[mini(stage, LEVEL_COUNT - 1)].enemy_indices
	if order.is_empty():
		return
	var phase_time: float = game.run_time - level_started_at
	var hard_phase: bool = phase_time >= PHASE_DURATION
	var count := 5 if not hard_phase else 7
	var capacity: int = MAX_ACTIVE_ENEMIES - game.enemies.size()
	count = mini(count, capacity)
	for index in range(count):
		var data: Resource = Catalog.ENEMIES[order[(index + horde_index) % order.size()]]
		var elite := 1 if hard_phase and index % 7 == 0 else 0
		if hard_phase and index % 11 == 0:
			elite = 2
		game.spawn_enemy(data, elite, enemy_difficulty())

func enemy_difficulty() -> float:
	# Health grows steadily; the cap keeps late practice playable while still dramatic.
	var phase_time: float = game.run_time - level_started_at
	var phase_growth := 0.0 if phase_time < PHASE_DURATION else 0.18
	return (0.82 + phase_growth + stage * 0.10) * game.map_data.spawn_scale

func complete_boss() -> void:
	if not boss_spawned:
		return
	boss_defeated += 1
	if boss_defeated >= LEVEL_COUNT:
		boss_spawned = false
		game.boss_killed = true
	else:
		transition_left = 3.0
		game.combat.hostile.clear()
		game.hud.announce("level_cleared")
