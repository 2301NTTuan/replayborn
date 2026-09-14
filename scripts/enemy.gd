extends Node2D
const Skills = preload("res://scripts/core/enemy_skills.gd")
var animation_state: StringName = &"idle"
var windup: float = 0.0
var attack_hold: float = 0.0
var death_left: float = 0.42

var spec: Resource
var target: Node2D
var game: Node
var health: float = 3
var max_health: float = 3
var radius: float = 24
var speed: float = 120
var contact_damage: int = 10
var cycle: float = 0
var shot_time: float = 1.5
var dash_direction: Vector2 = Vector2.ZERO
var flash: float = 0
var elite: int = 0
var spawn_protection: float = 0.7
var orbit_sign: float = 1
var dead: bool = false
var serial: int = 0
var skill_primary: float = 1.1
var skill_secondary: float = 2.7
var skill_tertiary: float = 4.6
var dash_time: float = 0.0
var dash_vector: Vector2 = Vector2.ZERO
var boss_target_range: float = 720.0

func setup(data: Resource, owner_game: Node, variant: int, difficulty: float) -> void:
	spec = data
	game = owner_game
	target = game.player
	elite = variant
	var durability: float = game.enemy_durability_multiplier()
	if String(data.id).begins_with("boss_"):
		durability *= 1.22
	health = data.health * difficulty * durability * (2.3 if elite > 0 else 1.0)
	max_health = health
	radius = data.radius * (1.2 if elite > 0 else 1.0)
	speed = data.speed * (1.3 if elite == 1 else 1.0)
	contact_damage = maxi(1, roundi(data.damage * (0.72 + (difficulty - 1.0) * 0.34))) + (3 if elite > 0 else 0)
	if String(data.id).begins_with("boss_"):
		boss_target_range = 620.0 + float(_boss_rank()) * 85.0
	orbit_sign = -1 if randf() < 0.5 else 1

func advance(delta: float) -> void:
	if dead:
		death_left -= delta
		animation_state = &"death"
		queue_redraw()
		return
	flash = maxf(0, flash - delta)
	if spawn_protection > 0:
		spawn_protection -= delta
		queue_redraw()
		return
	cycle += delta
	shot_time -= delta
	select_target()
	var direction: Vector2 = position.direction_to(target.position)
	if String(spec.id).begins_with("boss_"):
		_advance_boss(delta, direction)
	elif spec.family >= 0:
		Skills.advance(self, delta, direction)
	else:
		match spec.id:
			"charger":
				if cycle < 1.6:
					position += direction * speed * delta
					dash_direction = direction
				elif cycle >= 2.3 and cycle < 2.8:
					position += dash_direction * 620 * delta
				elif cycle >= 2.8:
					cycle = 0
			"shooter":
				var distance: float = position.distance_to(target.position)
				position += direction * speed * delta
				if shot_time <= 0:
					dash_direction = direction
					dash_time = 0.38
					shot_time = 3.2
			"orbiter":
				var tangent := Vector2(-direction.y, direction.x) * orbit_sign
				position += (direction * 0.65 + tangent * 0.75).normalized() * speed * delta
			_:
				position += direction * speed * delta
	if elite == 2 and shot_time <= 0:
		for index in range(4):
			game.combat.enemy_shot(position, Vector2.RIGHT.rotated(TAU * index / 4), 210, 8)
		shot_time = 2.8
	position = position.clamp(game.ARENA.position + Vector2.ONE * radius, game.ARENA.end - Vector2.ONE * radius)
	queue_redraw()

func select_target() -> void:
	if game == null or not is_instance_valid(game.player):
		return
	var is_boss := String(spec.id).begins_with("boss_")
	var candidates: Array[Node2D] = [game.player]
	for echo in game.echoes:
		if is_instance_valid(echo) and not echo.dead:
			candidates.append(echo)
	var nearest: Node2D = null
	var nearest_distance := INF
	for candidate in candidates:
		var distance := position.distance_to(candidate.position)
		if is_boss and distance > boss_target_range:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	# Bosses keep pressuring the player if no replay object is inside their range.
	if nearest == null:
		target = game.player
	else:
		target = nearest

func _advance_boss(delta: float, direction: Vector2) -> void:
	# Every boss owns three independent attacks. The later variants use faster, denser patterns.
	var rank := _boss_rank()
	skill_primary -= delta
	skill_secondary -= delta
	skill_tertiary -= delta
	attack_hold = maxf(0.0, attack_hold - delta)
	animation_state = &"run"
	if minf(skill_primary, minf(skill_secondary, skill_tertiary)) <= 0.45:
		animation_state = &"windup"
	if attack_hold > 0.0 or dash_time > 0.0:
		animation_state = &"attack"
	if dash_time > 0:
		dash_time -= delta
		position += dash_vector * (510.0 + rank * 35.0) * delta
	else:
		position += direction * speed * delta
	if skill_primary <= 0:
		attack_hold = 0.3
		animation_state = &"attack"
		_boss_ring(8 + rank * 2, 205.0 + rank * 18.0, 10 + rank * 2)
		skill_primary = maxf(1.15, 2.45 - rank * 0.16)
	if skill_secondary <= 0:
		attack_hold = 0.3
		animation_state = &"attack"
		_boss_fan(direction, 3 + rank, 0.20 + rank * 0.035, 300.0 + rank * 16.0, 12 + rank * 2)
		skill_secondary = maxf(1.7, 3.7 - rank * 0.20)
	if skill_tertiary <= 0:
		attack_hold = 0.3
		animation_state = &"attack"
		match String(spec.id):
			"boss_warden":
				_boss_cross(250.0, 16)
			"boss_hunter":
				dash_vector = direction
				dash_time = 0.55
				_boss_fan(direction, 5, 0.14, 360.0, 16)
			"boss_sentinel":
				_boss_ring(18, 165.0, 14)
				_boss_cross(300.0, 15)
			"boss_reaper":
				dash_vector = direction.rotated(0.35 if orbit_sign > 0 else -0.35)
				dash_time = 0.7
				_boss_ring(14, 290.0, 18)
			"boss_archon":
				_boss_ring(24, 255.0, 20)
				_boss_fan(direction, 9, 0.13, 380.0, 20)
		skill_tertiary = maxf(2.6, 5.6 - rank * 0.35)

func _boss_rank() -> int:
	match String(spec.id):
		"boss_hunter": return 1
		"boss_sentinel": return 2
		"boss_reaper": return 3
		"boss_archon": return 4
	return 0

func _boss_ring(count: int, projectile_speed: float, damage: int) -> void:
	for index in range(count):
		game.combat.enemy_shot(position, Vector2.RIGHT.rotated(TAU * index / count + cycle * 0.28), projectile_speed, damage)

func _boss_fan(direction: Vector2, count: int, spacing: float, projectile_speed: float, damage: int) -> void:
	for index in range(count):
		var angle := (float(index) - float(count - 1) * 0.5) * spacing
		game.combat.enemy_shot(position, direction.rotated(angle), projectile_speed, damage)

func _boss_cross(projectile_speed: float, damage: int) -> void:
	for index in range(4):
		game.combat.enemy_shot(position, Vector2.RIGHT.rotated(TAU * index / 4 + cycle * 0.15), projectile_speed, damage)

func _draw() -> void:
	if spec == null:
		return
	if has_node("ArtVisual"):
		if dead:
			return
		if windup > 0.0:
			draw_line(Vector2.ZERO, dash_direction * 180.0, Color("ffd166", 0.65), 3)
			draw_arc(Vector2.ZERO, radius + 8, 0, TAU, 24, Color("ffd166", 0.8), 2)
		var art_tint: Color = Color.WHITE if flash > 0 and not game.reduced_effects else spec.tint
		if spawn_protection > 0:
			draw_arc(Vector2.ZERO, radius + 12, 0, TAU, 24, art_tint, 2)
		if spec.id == "charger" and cycle >= 1.6 and cycle < 2.3:
			draw_line(Vector2.ZERO, dash_direction * 310, Color(0.8, 0.5, 1, 0.65), 5)
		if elite > 0:
			draw_arc(Vector2.ZERO, radius + 7, 0, TAU, 24, Color("ffe6a0") if elite == 1 else Color("a4ffff"), 3)
		if health < max_health:
			draw_line(Vector2(-radius, -radius - 13), Vector2(radius, -radius - 13), Color("28334a"), 4)
			draw_line(Vector2(-radius, -radius - 13), Vector2(-radius + radius * 2 * health / max_health, -radius - 13), Color("ffbac4"), 4)
		return
	var tint: Color = Color.WHITE if flash > 0 and not game.reduced_effects else spec.tint
	if spawn_protection > 0:
		tint.a = 0.4
		draw_arc(Vector2.ZERO, radius + 12, 0, TAU, 24, tint, 2)
	match spec.id:
		"runner":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -radius), Vector2(radius, radius), Vector2(-radius, radius)]), tint)
		"charger", "boss":
			draw_circle(Vector2.ZERO, radius, tint)
			draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 24, Color("172239"), 5)
			if spec.id == "charger" and cycle >= 1.6 and cycle < 2.3:
				draw_line(Vector2.ZERO, dash_direction * 310, Color(0.8, 0.5, 1, 0.65), 5)
		"shooter":
			draw_colored_polygon(PackedVector2Array([Vector2(0,-radius), Vector2(radius,0), Vector2(0,radius), Vector2(-radius,0)]), tint)
		"orbiter":
			draw_arc(Vector2.ZERO, radius, 0, TAU, 16, tint, 8)
		_:
			draw_rect(Rect2(-radius, -radius, radius * 2, radius * 2), tint)
	if elite > 0:
		draw_arc(Vector2.ZERO, radius + 7, 0, TAU, 24, Color("ffe6a0") if elite == 1 else Color("a4ffff"), 3)
	if health < max_health:
		draw_line(Vector2(-radius, -radius - 13), Vector2(radius, -radius - 13), Color("28334a"), 4)
		draw_line(Vector2(-radius, -radius - 13), Vector2(-radius + radius * 2 * health / max_health, -radius - 13), Color("ffbac4"), 4)
