extends Node2D

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

func setup(data: Resource, owner_game: Node, variant: int, difficulty: float) -> void:
	spec = data
	game = owner_game
	target = game.player
	elite = variant
	health = data.health * difficulty * (2.3 if elite > 0 else 1.0)
	max_health = health
	radius = data.radius * (1.2 if elite > 0 else 1.0)
	speed = data.speed * (1.3 if elite == 1 else 1.0)
	contact_damage = data.damage + (5 if elite > 0 else 0)
	orbit_sign = -1 if randf() < 0.5 else 1

func advance(delta: float) -> void:
	flash = maxf(0, flash - delta)
	if spawn_protection > 0:
		spawn_protection -= delta
		queue_redraw()
		return
	cycle += delta
	shot_time -= delta
	var direction: Vector2 = position.direction_to(target.position)
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
			if distance > 460:
				position += direction * speed * delta
			elif distance < 300:
				position -= direction * speed * delta
			if shot_time <= 0:
				game.combat.enemy_shot(position, direction, 280, 8)
				shot_time = 2.2
		"orbiter":
			var tangent := Vector2(-direction.y, direction.x) * orbit_sign
			position += (direction * 0.65 + tangent * 0.75).normalized() * speed * delta
		"boss":
			position += direction * speed * delta
			if shot_time <= 0:
				var count: int = 12 if health > max_health * 0.5 else 18
				for index in range(count):
					game.combat.enemy_shot(position, Vector2.RIGHT.rotated(TAU * index / count + cycle * 0.2), 230, 12)
				shot_time = 2.0 if count == 12 else 1.4
		_:
			position += direction * speed * delta
	if elite == 2 and shot_time <= 0:
		for index in range(4):
			game.combat.enemy_shot(position, Vector2.RIGHT.rotated(TAU * index / 4), 210, 8)
		shot_time = 2.8
	position = position.clamp(game.ARENA.position + Vector2.ONE * radius, game.ARENA.end - Vector2.ONE * radius)
	queue_redraw()

func _draw() -> void:
	if spec == null:
		return
	if has_node("ArtVisual"):
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
