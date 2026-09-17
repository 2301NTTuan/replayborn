extends RefCounted

func apply(game: Node, weapon: Resource, polygon: PackedVector2Array, targets: Array) -> Dictionary:
	if polygon.size() < 3:
		return {"hits": 0, "captured": 0}
	var area: float = game.circuit.polygon_area(polygon)
	var area_scale: float = clampf(sqrt(area / 24000.0), 0.8, 1.65)
	if area < 42000.0:
		area_scale *= 1.0 + float(game.stats.compression)
	var base_damage: float = weapon.finisher_damage * (1.0 + float(game.stats.damage) + float(game.stats.circuit_power)) * area_scale
	var result: Dictionary = {"hits": 0, "captured": targets.size(), "weapon": weapon.id}
	match String(weapon.id):
		"scatter":
			_apply_scatter(game, weapon, polygon, targets, base_damage, result)
		"lance":
			_apply_lance(game, weapon, polygon, targets, base_damage, result)
		_:
			_apply_pulse(game, weapon, targets, base_damage, result)
	for enemy in targets:
		if is_instance_valid(enemy) and not enemy.dead:
			enemy.apply_circuit(polygon)
			enemy.time_lock_left = maxf(enemy.time_lock_left, (weapon.finisher_lock + float(game.stats.time_lock)) * (0.45 if String(enemy.spec.id).begins_with("boss_") else 1.0))
	return result

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
