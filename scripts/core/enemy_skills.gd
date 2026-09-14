extends RefCounted

# Each family has its own movement and attack. A fixed aim during windup makes
# attacks avoidable; projectile collision is shared with the existing combat system.
static func advance(enemy: Node2D, delta: float, direction: Vector2) -> void:
	var family: int = enemy.spec.family
	var distance: float = enemy.position.distance_to(enemy.target.position)
	if enemy.dash_time > 0.0:
		enemy.dash_time -= delta
		enemy.position += enemy.dash_vector * (360.0 + family * 9.0) * delta
		enemy.animation_state = &"attack"
		return
	if enemy.attack_hold > 0.0:
		enemy.attack_hold -= delta
		enemy.animation_state = &"attack"
		return
	if enemy.windup > 0.0:
		enemy.windup -= delta
		enemy.animation_state = &"windup"
		if enemy.windup <= 0.0:
			fire(enemy, family)
			enemy.attack_hold = 0.28
			enemy.shot_time = 3.0 + float(family % 3) * 0.45
		return
	var movement := direction
	if family in [3, 5, 7, 10, 13]:
		movement = direction if distance > 390.0 else (-direction if distance < 240.0 else Vector2.ZERO)
	elif family in [4, 8, 11, 14]:
		movement = (direction * 0.6 + Vector2(-direction.y, direction.x) * enemy.orbit_sign * 0.8).normalized()
	enemy.position += movement * enemy.speed * delta
	enemy.animation_state = &"run" if movement.length_squared() > 0.01 else &"idle"
	if enemy.shot_time <= 0.0 and distance < (310.0 if family in [0, 1, 2, 6, 9, 12] else 650.0):
		enemy.windup = 0.65 if family in [2, 5, 13] else 0.45
		enemy.dash_direction = direction

static func fire(enemy: Node2D, family: int) -> void:
	var aim: Vector2 = enemy.dash_direction
	var damage: int = maxi(3, enemy.contact_damage / 2)
	match family:
		0: zone(enemy, 86.0, 0.72, damage, 1.7) # Poison cloud.
		1: dash(enemy, aim, 0.28) # Quick leap.
		2: dash(enemy, aim, 0.65) # Long, telegraphed charge.
		3: zone(enemy, 112.0, 0.8, damage, 1.9) # Acid pool.
		4: dash(enemy, aim, 0.42) # Paired blade lunge.
		5: dash(enemy, aim, 0.52) # Heavy needle charge.
		6: dash(enemy, aim, 0.48) # Pincer rush.
		7: zone(enemy, 130.0, 0.7, damage, 1.5) # Electrical field.
		8: dash(enemy, aim, 0.38) # Tail swipe.
		9:
			dash(enemy, aim, 0.44) # Dash slash.
		10: zone(enemy, 120.0, 0.65, damage, 2.6) # Lingering spores.
		11: dash(enemy, aim.rotated(0.45 * enemy.orbit_sign), 0.42) # Dive.
		12: dash(enemy, aim, 0.5) # Spectral rush.
		13: zone(enemy, 150.0, 0.9, damage, 1.8) # Prism field.
		14: zone(enemy, 175.0, 0.85, damage, 2.3) # Venom crown.

static func zone(enemy: Node2D, radius: float, delay: float, damage: int, duration: float) -> void:
	enemy.game.combat.enemy_zones.append({"position": enemy.position, "radius": radius, "delay": delay, "duration": duration, "damage": damage, "age": 0.0, "hit": false})

static func dash(enemy: Node2D, aim: Vector2, duration: float) -> void:
	enemy.dash_vector = aim
	enemy.dash_time = duration

static func fan(enemy: Node2D, aim: Vector2, count: int, spread: float, speed: float, damage: int, life: float = 3.0) -> void:
	for index in range(count):
		var direction := aim.rotated((index - (count - 1) * 0.5) * spread)
		enemy.game.combat.enemy_shot(enemy.position, direction, speed, damage, life)

static func ring(enemy: Node2D, count: int, speed: float, damage: int, life: float = 3.0) -> void:
	for index in range(count):
		fan(enemy, Vector2.from_angle(TAU * index / count), 1, 0.0, speed, damage, life)
