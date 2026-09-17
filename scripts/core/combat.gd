extends RefCounted

const MAX_FRIENDLY: int = 360
const MAX_HOSTILE: int = 150
const MAX_EFFECTS: int = 72
const MAX_ACTIVE_MINES: int = 6
const MAX_ENEMY_ZONES: int = 34
var game: Node
var friendly: Array = []
var hostile: Array = []
var effects: Array = []
var enemy_zones: Array = []
var fire_left: float = 0
var grid: Dictionary = {}
var secondary_cooldowns: Dictionary = {}

func _init(owner_game: Node) -> void:
	game = owner_game

func _dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func add_shot(shot: Dictionary) -> void:
	if friendly.size() >= MAX_FRIENDLY:
		friendly.remove_at(0)
	if friendly.size() >= MAX_FRIENDLY:
		return
	var projectile := shot.duplicate(true)
	projectile.hit = []
	friendly.append(projectile)

func add_effect(effect: Dictionary) -> void:
	var visual := effect.duplicate(true)
	if not visual.has("life"):
		visual.life = 0.2
	if bool(_dict_value(visual, "mine", false)):
		_trim_active_mines()
	else:
		visual.life = clampf(float(visual.life), 0.03, 3.0)
	_trim_effects()
	effects.append(visual)

func add_enemy_zone(zone: Dictionary) -> void:
	if enemy_zones.size() >= MAX_ENEMY_ZONES:
		enemy_zones.remove_at(0)
	enemy_zones.append(zone.duplicate(true))

func _trim_active_mines() -> void:
	var active_mines: int = 0
	for effect in effects:
		if bool(_dict_value(effect, "mine", false)) and not bool(_dict_value(effect, "detonated", false)):
			active_mines += 1
	if active_mines < MAX_ACTIVE_MINES:
		return
	for index in range(effects.size()):
		var effect: Dictionary = effects[index]
		if bool(_dict_value(effect, "mine", false)) and not bool(_dict_value(effect, "detonated", false)):
			effects.remove_at(index)
			return

func _trim_effects() -> void:
	while effects.size() >= MAX_EFFECTS:
		var removed: bool = false
		for index in range(effects.size()):
			if not bool(_dict_value(effects[index], "mine", false)):
				effects.remove_at(index)
				removed = true
				break
		if not removed:
			effects.remove_at(0)

func fire(target: Node2D, delta: float) -> Array:
	fire_left -= delta
	var result: Array = []
	if target == null or fire_left > 0:
		return result
	var weapon: Resource = game.weapon
	var stats: Dictionary = game.stats
	var pellets: int = mini(7, weapon.pellets + int(stats.pellets))
	var direction: Vector2 = game.player.facing.normalized()
	if target != null and is_instance_valid(target):
		direction = game.player.position.direction_to(target.position)
		game.player.facing = direction
	var muzzle: Vector2 = game.player.position + Vector2(0, -22) + direction * 34.0
	for index in range(pellets):
		var angle: float = (index - (pellets - 1) * 0.5) * maxf(weapon.spread, 0.10)
		var shot: Dictionary = {
			"position": muzzle, "velocity": direction.rotated(angle) * weapon.speed * (1 + stats.bullet_speed),
			"damage": weapon.damage * 1.5 * (1 + stats.damage) * (2.0 if randf() < stats.crit else 1.0),
			"pierce": weapon.pierce + int(stats.pierce), "life": weapon.lifetime * (1 + stats.lifetime),
			"ghost": false
		}
		result.append(shot.duplicate(true))
		add_shot(shot)
	var overdrive_rate: float = 0.78 if game.overdrive_left > 0.0 else 1.0
	fire_left = maxf(0.09, weapon.interval * pow(0.9, stats.haste) * overdrive_rate)
	game.sound.play("shot")
	game.player.register_shot()
	return result

func enemy_shot(origin: Vector2, direction: Vector2, speed: float, damage: int, lifetime: float = 7.0) -> void:
	if hostile.size() >= MAX_HOSTILE:
		hostile.remove_at(0)
	if hostile.size() < MAX_HOSTILE:
		hostile.append({"position": origin, "velocity": direction * speed, "damage": damage, "life": lifetime})

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
			result.append_array(_dict_value(grid, Vector2i(x, y), []))
	return result

func advance(delta: float) -> void:
	build_grid()
	advance_secondary(delta)
	for index in range(friendly.size() - 1, -1, -1):
		var bullet: Dictionary = friendly[index]
		var previous: Vector2 = bullet.position
		if bool(_dict_value(bullet, "homing", false)):
			var homing_target: Variant = _dict_value(bullet, "target", null)
			if is_instance_valid(homing_target) and homing_target is Node2D and not homing_target.dead:
				var desired: Vector2 = bullet.position.direction_to(homing_target.position) * bullet.velocity.length()
				bullet.velocity = bullet.velocity.lerp(desired, minf(1.0, delta * 7.0))
		bullet.position += bullet.velocity * delta
		bullet.life -= delta
		if bool(_dict_value(bullet, "drone_missile", false)):
			var missile_target: Variant = _dict_value(bullet, "target", null)
			var has_impact: bool = bullet.life <= 0.0
			if is_instance_valid(missile_target) and missile_target is Node2D and not missile_target.dead:
				has_impact = has_impact or bullet.position.distance_to(missile_target.position) <= missile_target.radius + 16.0
			if has_impact:
				_detonate_drone(bullet)
				friendly.remove_at(index)
				continue
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
			game.damage_enemy(enemy, float(bullet.damage), "weapon")
			bullet.hit.append(enemy.serial)
			game.sound.play("hit")
			if not game.reduced_effects:
				add_effect({"position": enemy.position, "life": 0.18})
			if int(_dict_value(bullet, "pierce", 0)) <= 0:
				bullet.life = 0
				break
			bullet.pierce = int(_dict_value(bullet, "pierce", 0)) - 1
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
	for index in range(enemy_zones.size() - 1, -1, -1):
		var zone: Dictionary = enemy_zones[index]
		zone.age = float(_dict_value(zone, "age", 0.0)) + delta
		if not bool(_dict_value(zone, "hit", false)) and zone.age >= float(zone.delay):
			if game.player.position.distance_to(zone.position) <= float(zone.radius):
				game.take_damage(int(zone.damage))
			zone.hit = true
		if zone.age >= float(zone.delay) + float(zone.duration):
			enemy_zones.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		if not effect.has("position") or not effect.has("life"):
			effects.remove_at(index)
			continue
		if bool(_dict_value(effect, "mine", false)):
			effect.age = float(_dict_value(effect, "age", 0.0)) + delta
			if not bool(_dict_value(effect, "armed", false)) and effect.age >= 0.55:
				effect.armed = true
			if bool(_dict_value(effect, "armed", false)) and not bool(_dict_value(effect, "detonated", false)):
				var triggered: bool = effect.age >= 2.0
				for enemy in game.enemies:
					if not enemy.dead and enemy.position.distance_to(effect.position) <= float(effect.radius):
						triggered = true
				if triggered:
					# The blast hits every enemy in range, including a boss.
					for enemy in game.enemies:
						if not enemy.dead and enemy.position.distance_to(effect.position) <= float(effect.radius):
							game.damage_enemy(enemy, float(effect.damage), "weapon")
					effect.detonated = true
					effect.life = 0.34
					game.sound.play("secondary_mine")
			if bool(_dict_value(effect, "detonated", false)):
				effect.life -= delta
		else:
			effect.life -= delta
		if effects[index].life <= 0:
			effects.remove_at(index)

func _detonate_drone(missile: Dictionary) -> void:
	var radius: float = float(_dict_value(missile, "impact_radius", 58.0))
	var damage: float = float(_dict_value(missile, "damage", 8.0))
	for enemy in game.enemies:
		if enemy.dead or enemy.spawn_protection > 0.0:
			continue
		if enemy.position.distance_to(missile.position) <= radius + enemy.radius:
			game.damage_enemy(enemy, damage, "weapon")
	add_effect({"position": missile.position, "life": 0.32, "drone_burst": true, "radius": radius})
	game.sound.play("hit")

func advance_secondary(delta: float) -> void:
	for weapon_id in game.secondary_weapons.keys():
		var level: int = int(game.secondary_weapons[weapon_id])
		var cooldown: float = float(_dict_value(secondary_cooldowns, weapon_id, 0.0)) - delta
		if cooldown > 0.0:
			secondary_cooldowns[weapon_id] = cooldown
			continue
		var target: Node2D = game.nearest_enemy()
		if target == null:
			secondary_cooldowns[weapon_id] = 0.2
			continue
		match weapon_id:
			"boomerang":
				add_shot({"position": game.player.position, "velocity": game.player.position.direction_to(target.position) * (440.0 + level * 35.0), "damage": 3.0 + level * 2.0, "pierce": 1 + level, "life": 1.2 + level * 0.12, "ghost": false, "secondary_id": weapon_id})
				game.sound.play("secondary_boomerang")
				secondary_cooldowns[weapon_id] = maxf(0.8, 1.8 - level * 0.16)
			"orbit":
				var radius := 82.0 + level * 12.0
				add_effect({"position": game.player.position, "life": 0.18, "orbit": true, "radius": radius})
				for enemy in game.enemies:
					if not enemy.dead and enemy.position.distance_to(game.player.position) <= radius:
						enemy.health -= 4.0 + level * 2.5
						if enemy.health <= 0: game.kill_enemy(enemy)
				game.sound.play("secondary_orbit")
				secondary_cooldowns[weapon_id] = maxf(0.45, 1.0 - level * 0.08)
			"drone":
				var drone_count: int = 1 + int((level - 1) / 2)
				var drone_targets := _drone_targets(drone_count)
				for drone_index in range(drone_targets.size()):
					var drone_target: Node2D = drone_targets[drone_index]
					var drone_angle: float = game.run_time * 1.35 + TAU * drone_index / drone_count
					var drone_pos: Vector2 = game.player.position + Vector2.from_angle(drone_angle) * (54.0 + level * 3.0) + Vector2(0, -18)
					var drone_velocity: Vector2 = drone_pos.direction_to(drone_target.position) * (590.0 + level * 45.0)
					add_shot({"position": drone_pos, "velocity": drone_velocity, "damage": 7.0 + level * 3.5, "life": 1.8, "ghost": false, "secondary_id": weapon_id, "drone_missile": true, "homing": true, "target": drone_target, "impact_radius": 46.0 + level * 7.0, "drone_level": level})
					add_effect({"position": drone_pos, "end": drone_target.position, "life": 0.12, "drone_launch": true})
				game.sound.play("secondary_drone")
				secondary_cooldowns[weapon_id] = maxf(0.35, 1.25 - level * 0.12)
			"mine":
				add_effect({"position": game.player.position, "life": 2.35, "age": 0.0, "mine": true, "armed": false, "detonated": false, "damage": 12.0 + level * 6.0, "radius": 75.0 + level * 12.0})
				game.sound.play("secondary_mine")
				secondary_cooldowns[weapon_id] = maxf(1.2, 3.2 - level * 0.25)
			"beam":
				add_effect({"position": game.player.position, "end": target.position, "life": 0.16, "beam": true})
				target.health -= 10.0 + level * 5.0
				if target.health <= 0: game.kill_enemy(target)
				game.sound.play("secondary_beam")
				secondary_cooldowns[weapon_id] = maxf(1.0, 2.7 - level * 0.22)

func _drone_targets(count: int) -> Array:
	var available: Array = []
	for enemy in game.enemies:
		if not enemy.dead and enemy.spawn_protection <= 0.0:
			available.append(enemy)
	available.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.position.distance_squared_to(game.player.position) < b.position.distance_squared_to(game.player.position))
	var result: Array = []
	for index in range(mini(count, available.size())):
		result.append(available[index])
	return result
