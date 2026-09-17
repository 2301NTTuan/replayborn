extends RefCounted

enum SequencePhase { IDLE, LOCK, FINISHER, RELEASE }
const LOCK_TIME: float = 0.10
const FINISHER_TIME: float = 0.18
const RELEASE_TIME: float = 0.16

var phase: SequencePhase = SequencePhase.IDLE
var phase_left: float = 0.0
var pending: Dictionary = {}

func apply(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array) -> Dictionary:
	# Immediate application remains available for deterministic tools and direct
	# unit smoke checks. Live runs use begin()/advance() below.
	if polygon.size() < 3:
		return {"hits": 0, "captured": 0}
	var result := _apply_damage(game, weapon, polygon, targets)
	_lock_targets(weapon, polygon, targets, game.stats)
	return result

func begin(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array) -> Dictionary:
	if polygon.size() < 3:
		return {"hits": 0, "captured": 0}
	cancel()
	pending = {"weapon": weapon, "polygon": polygon.duplicate(), "targets": targets.duplicate()}
	_lock_targets(weapon, polygon, targets, game.stats)
	phase = SequencePhase.LOCK
	phase_left = LOCK_TIME
	return {"hits": 0, "captured": targets.size(), "weapon": weapon.id, "queued": true}

func advance(game: Node, delta: float) -> Dictionary:
	if phase == SequencePhase.IDLE:
		return {}
	phase_left = maxf(0.0, phase_left - delta)
	if phase_left > 0.0:
		return {}
	if phase == SequencePhase.LOCK:
		phase = SequencePhase.FINISHER
		phase_left = FINISHER_TIME
		return _apply_damage(game, pending.weapon, pending.polygon, pending.targets)
	if phase == SequencePhase.FINISHER:
		phase = SequencePhase.RELEASE
		phase_left = RELEASE_TIME
		return {"released": false}
	phase = SequencePhase.IDLE
	pending.clear()
	return {"released": true}

func cancel() -> void:
	phase = SequencePhase.IDLE
	phase_left = 0.0
	pending.clear()

func phase_name() -> String:
	return ["idle", "lock", "finisher", "release"][phase]

func _apply_damage(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array) -> Dictionary:
	var area: float = game.circuit.polygon_area(polygon)
	var area_scale: float = clampf(sqrt(area / 24000.0), 0.8, 1.65)
	if area < 42000.0:
		area_scale *= 1.0 + float(game.stats.compression)
	var overdrive_damage: float = 1.20 if game.overdrive_left > 0.0 else 1.0
	var base_damage: float = weapon.finisher_damage * (1.0 + float(game.stats.damage) + float(game.stats.circuit_power)) * area_scale * overdrive_damage
	var result: Dictionary = {"hits": 0, "captured": targets.size(), "weapon": weapon.id}
	match String(weapon.id):
		"scatter":
			_apply_scatter(game, weapon, polygon, targets, base_damage, result)
		"lance":
			_apply_lance(game, weapon, polygon, targets, base_damage, result)
		_:
			_apply_pulse(game, weapon, targets, base_damage, result)
	return result

func _lock_targets(weapon: Resource, polygon: PackedVector2Array, targets: Array, stats: Dictionary) -> void:
	for enemy in targets:
		if is_instance_valid(enemy) and not enemy.dead:
			enemy.apply_circuit(polygon)
			enemy.time_lock_left = maxf(enemy.time_lock_left, (weapon.finisher_lock + float(stats.time_lock)) * (0.45 if String(enemy.spec.id).begins_with("boss_") else 1.0))

func _apply_pulse(game: Node, weapon: Resource, targets: Array, base_damage: float, result: Dictionary) -> void:
	var remaining: Array = targets.duplicate()
	var origin: Vector2 = game.player.position
	var chain_count: int = mini(remaining.size(), weapon.finisher_count + int(game.stats.pulse_relay))
	for chain_index in range(chain_count):
		remaining.sort_custom(func(a: Node2D, b: Node2D) -> bool: return origin.distance_squared_to(a.position) < origin.distance_squared_to(b.position))
		var target: Node2D = remaining.pop_front()
		var decay: float = maxf(0.68, weapon.finisher_decay + float(game.stats.pulse_decay))
		game.damage_enemy(target, base_damage * pow(decay, chain_index), "circuit")
		game.combat.add_effect({"position": origin, "end": target.position, "life": 0.22, "circuit_chain": true})
		origin = target.position
		result.hits += 1
	if int(game.stats.pulse_overload) > 0 and chain_count > 0:
		for enemy in game.enemies:
			if not enemy.dead and enemy.position.distance_to(origin) <= 90.0:
				game.damage_enemy(enemy, base_damage * 0.35, "circuit")

func _apply_scatter(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array, base_damage: float, result: Dictionary) -> void:
	var center: Vector2 = _centroid(polygon)
	var focus_bonus: float = 0.18 * float(game.stats.scatter_focus)
	for enemy in targets:
		var centrality: float = clampf(1.0 - enemy.position.distance_to(center) / 420.0, 0.0, 1.0)
		game.damage_enemy(enemy, base_damage * (0.72 + centrality * (0.58 + focus_bonus)), "circuit")
		result.hits += 1
	if int(game.stats.scatter_shrapnel) > 0:
		for enemy in targets:
			if is_instance_valid(enemy) and enemy.dead:
				game.combat.add_effect({"position": enemy.position, "life": 0.24, "circuit_shrapnel": true})

func _apply_lance(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array, base_damage: float, result: Dictionary) -> void:
	for enemy in targets:
		var edge_distance: float = _distance_to_edges(enemy.position, polygon)
		var edge_bonus: float = (0.35 + float(game.stats.lance_collapse)) if edge_distance <= 70.0 else 0.0
		game.damage_enemy(enemy, base_damage * (1.0 + edge_bonus), "circuit")
		result.hits += 1
	if int(game.stats.lance_resonance) > 0:
		for enemy in targets:
			if is_instance_valid(enemy) and not enemy.dead:
				game.damage_enemy(enemy, base_damage * 0.32, "circuit")

func _centroid(polygon: PackedVector2Array) -> Vector2:
	var result := Vector2.ZERO
	for point in polygon:
		result += point
	return result / maxf(1.0, polygon.size())

func _distance_to_edges(point: Vector2, polygon: PackedVector2Array) -> float:
	var result: float = INF
	for index in range(polygon.size()):
		result = minf(result, point.distance_to(Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])))
	return result
