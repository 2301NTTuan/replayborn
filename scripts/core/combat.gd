extends RefCounted

const MAX_FRIENDLY: int = 600
const MAX_HOSTILE: int = 240
var game: Node
var friendly: Array = []
var hostile: Array = []
var effects: Array = []
var fire_left: float = 0
var grid: Dictionary = {}

func _init(owner_game: Node) -> void:
	game = owner_game

func add_shot(shot: Dictionary) -> void:
	if friendly.size() >= MAX_FRIENDLY:
		return
	var projectile := shot.duplicate(true)
	projectile.hit = []
	friendly.append(projectile)

func fire(target: Node2D, delta: float) -> Array:
	fire_left -= delta
	var result: Array = []
	if target == null or fire_left > 0:
		return result
	var weapon: Resource = game.weapon
	var stats: Dictionary = game.stats
	var pellets: int = mini(7, weapon.pellets + int(stats.pellets))
	var direction: Vector2 = game.player.position.direction_to(target.position)
	for index in range(pellets):
		var angle: float = (index - (pellets - 1) * 0.5) * maxf(weapon.spread, 0.10)
		var shot: Dictionary = {
			"position": game.player.position, "velocity": direction.rotated(angle) * weapon.speed * (1 + stats.bullet_speed),
			"damage": weapon.damage * (1 + stats.damage) * (2.0 if randf() < stats.crit else 1.0),
			"pierce": weapon.pierce + int(stats.pierce), "life": weapon.lifetime * (1 + stats.lifetime),
			"echo_multiplier": 1 + stats.echo_power, "ghost": false
		}
		result.append(shot.duplicate(true))
		add_shot(shot)
	fire_left = maxf(0.09, weapon.interval * pow(0.9, stats.haste))
	game.sound.play("shot")
	return result

func enemy_shot(origin: Vector2, direction: Vector2, speed: float, damage: int) -> void:
	if hostile.size() < MAX_HOSTILE:
		hostile.append({"position": origin, "velocity": direction * speed, "damage": damage, "life": 7.0})

func build_grid() -> void:
	grid.clear()
	for enemy in game.enemies:
		if enemy.dead:
			continue
		var cell := Vector2i(floori(enemy.position.x / 160), floori(enemy.position.y / 160))
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(enemy)

func candidates(start: Vector2, finish: Vector2) -> Array:
	var result: Array = []
	var low := Vector2i(floori((minf(start.x, finish.x) - 90) / 160), floori((minf(start.y, finish.y) - 90) / 160))
	var high := Vector2i(floori((maxf(start.x, finish.x) + 90) / 160), floori((maxf(start.y, finish.y) + 90) / 160))
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			result.append_array(grid.get(Vector2i(x, y), []))
	return result

func advance(delta: float) -> void:
	build_grid()
	for index in range(friendly.size() - 1, -1, -1):
		var bullet: Dictionary = friendly[index]
		var previous: Vector2 = bullet.position
		bullet.position += bullet.velocity * delta
		bullet.life -= delta
		var contacts: Array = []
		for enemy in candidates(previous, bullet.position):
			if enemy.dead or enemy.serial in bullet.hit or enemy.spawn_protection > 0:
				continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.position, previous, bullet.position)
			if closest.distance_squared_to(enemy.position) <= pow(enemy.radius + 7, 2):
				contacts.append({"enemy": enemy, "distance": previous.distance_squared_to(closest)})
		contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
		for contact in contacts:
			var enemy: Node2D = contact.enemy
			enemy.health -= bullet.damage
			enemy.flash = 0.09
			bullet.hit.append(enemy.serial)
			game.sound.play("hit")
			if not game.reduced_effects and effects.size() < 64:
				effects.append({"position": enemy.position, "life": 0.18})
			if enemy.health <= 0:
				game.kill_enemy(enemy)
			if bullet.pierce <= 0:
				bullet.life = 0
				break
			bullet.pierce -= 1
		if bullet.life <= 0 or not game.ARENA.has_point(bullet.position):
			friendly.remove_at(index)
	for index in range(hostile.size() - 1, -1, -1):
		var bullet: Dictionary = hostile[index]
		var previous: Vector2 = bullet.position
		bullet.position += bullet.velocity * delta
		bullet.life -= delta
		var closest := Geometry2D.get_closest_point_to_segment(game.player.position, previous, bullet.position)
		if closest.distance_squared_to(game.player.position) < 33.0 * 33.0:
			game.take_damage(bullet.damage)
			bullet.life = 0
		if bullet.life <= 0 or not game.ARENA.has_point(bullet.position):
			hostile.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		effects[index].life -= delta
		if effects[index].life <= 0:
			effects.remove_at(index)
