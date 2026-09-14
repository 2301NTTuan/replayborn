extends Node2D

const Catalog = preload("res://scripts/data/catalog.gd")
const Recorder = preload("res://scripts/core/recorder.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Director = preload("res://scripts/core/director.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Echo = preload("res://scripts/echo.gd")
const XPOrb = preload("res://scripts/xp_orb.gd")
const GoldOrb = preload("res://scripts/gold_orb.gd")
const ArtBridge = preload("res://scripts/visuals/art_bridge.gd")
const SoundBank = preload("res://scripts/sound_bank.gd")
const ARENA: Rect2 = Rect2(50, 450, 980, 1370)
enum State { PLAYING, PAUSED, UPGRADE, ENDED, TUTORIAL }
var state: State = State.PLAYING
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
var sound: Node
var art: RefCounted
var profile: Node
var weapon: Resource
var map_data: Resource
var combat: RefCounted
var director: RefCounted
var recorder: RefCounted = Recorder.new()
var enemies: Array = []
var xp_orbs: Array = []
var gold_orbs: Array = []
var echoes: Array = []
var upgrade_counts: Dictionary = {}
var secondary_weapons: Dictionary = {}
var offers: Array = []
var stats: Dictionary = {"damage": 0.0, "haste": 0, "pellets": 0, "pierce": 0, "bullet_speed": 0.0, "lifetime": 0.0, "armor": 0, "regen": 0, "echo_power": 0.0, "crit": 0.0, "siphon": 0, "grace": 0.0}
var run_level: int = 1
var run_xp: int = 0
var xp_to_next: int = 30
var health: float = 100
var max_health: float = 100
var damage_time: float = 0
var kills: int = 0
var run_tick: int = 0
var run_time: float = 0
var won: bool = false
var practice: bool = false
var reduced_effects: bool = false
var serial: int = 0
var echo_serial: int = 0
var boss: Node2D
var boss_killed: bool = false
var test_mode: bool = false
var levelup_pending: bool = false
var levelup_delay: float = 0.0

func _ready() -> void:
	profile = get_node("/root/Profile")
	practice = profile.practice
	# Weapons are bonded to the selected hero. The legacy profile.weapon value is
	# retained for save compatibility, but is no longer used to choose a weapon.
	weapon = Catalog.weapon_for_character(int(profile.data.character))
	# Current vertical slice deliberately ships one hero and one arena.
	map_data = Catalog.MAPS[0]
	sound = SoundBank.new()
	add_child(sound)
	combat = Combat.new(self)
	director = Director.new(self)
	player.arena = ARENA
	player.configure_character(0)
	player.configure_equipment(profile.data.equipment)
	var meta: Dictionary = profile.data.meta_upgrades
	max_health += int(meta.get("hp", 0)) * 15
	health = max_health
	stats.damage = int(meta.get("damage", 0)) * 0.05
	stats.armor = int(meta.get("armor", 0))
	stats.haste = int(meta.get("haste", 0))
	profile.settings_changed.connect(apply_settings)
	apply_settings()
	hud.bind_game(self)
	recorder.begin(player.position)
	RenderingServer.set_default_clear_color(map_data.background)
	art = ArtBridge.new(self)
	art.setup()
	if not profile.data.tutorial and not test_mode:
		state = State.TUTORIAL
		get_tree().paused = true
		hud.show_tutorial()

func apply_settings() -> void:
	reduced_effects = profile.data.reduced
	player.reduced_effects = reduced_effects
	sound.set_levels(profile.data.volume, profile.data.music)
	if combat != null and reduced_effects:
		combat.effects.clear()
	for echo in echoes:
		echo.tint = [Color("ff4fd8"), Color("ffd166"), Color("63f6ff")][profile.data.palette]

func begin_play() -> void:
	if state != State.TUTORIAL:
		return
	profile.setting("tutorial", true)
	state = State.PLAYING
	get_tree().paused = false
	hud.close_overlay()

func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		hud.show_pause()
	elif state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		hud.close_overlay()

func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_home() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and state == State.PLAYING:
		toggle_pause()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		toggle_pause()

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	# A single coordinator fixes movement, replay, collision and recording order.
	run_tick += 1
	run_time = run_tick / 60.0
	if levelup_pending:
		levelup_delay = maxf(0.0, levelup_delay - delta)
		if levelup_delay <= 0.0:
			levelup_pending = false
			offer_upgrades()
			return
	damage_time = maxf(0, damage_time - delta)
	health = minf(max_health, health + stats.regen * delta)
	player.advance(delta)
	if art != null:
		art.update_player(player)
	director.advance(delta)
	for enemy in enemies:
		enemy.advance(delta)
		if art != null:
			art.update_enemy(enemy)
	for index in range(xp_orbs.size() - 1, -1, -1):
		var orb: Node2D = xp_orbs[index]
		if orb.advance(delta):
			if orb.collected:
				gain_xp(orb.value)
			orb.queue_free()
			xp_orbs.remove_at(index)
	for index in range(gold_orbs.size() - 1, -1, -1):
		var gold: Node2D = gold_orbs[index]
		if gold.advance(delta):
			if gold.collected:
				profile.add_rewards(gold.value, 0)
				hud.show_pickup(gold.value, true)
			gold.queue_free()
			gold_orbs.remove_at(index)
	for index in range(echoes.size() - 1, -1, -1):
		var echo = echoes[index]
		if echo.dead or echo.advance():
			echo.queue_free()
			echoes.remove_at(index)
		else:
			art.update_echo(echo)
	var fired: Array = combat.fire(nearest_enemy(), delta)
	if recorder.record(player.position, fired):
		create_echo()
		recorder.begin(player.position)
	combat.advance(delta)
	for enemy in enemies:
		if not enemy.dead and enemy.spawn_protection <= 0 and enemy.position.distance_to(player.position) < enemy.radius + 25:
			take_damage(enemy.contact_damage)
		for echo in echoes:
			if not enemy.dead and enemy.spawn_protection <= 0 and not echo.dead and enemy.position.distance_to(echo.position) < enemy.radius + 25:
				take_echo_damage(echo, enemy.contact_damage)
	for index in range(enemies.size() - 1, -1, -1):
		if enemies[index].dead and enemies[index].death_left <= 0:
			enemies[index].queue_free()
			enemies.remove_at(index)
	if health <= 0:
		finish(false)
	elif (practice and run_tick >= 18000) or (not practice and boss_killed and (not is_instance_valid(boss) or boss.death_left <= 0.0)):
		finish(true)
	elif run_tick >= 54000:
		finish(false)
	hud.refresh()
	queue_redraw()

func take_echo_damage(echo: Node2D, amount: int) -> void:
	if echo.dead or echo.hurt_time > 0.0 or state != State.PLAYING:
		return
	echo.take_damage(amount)
	sound.play("hurt")

func nearest_enemy() -> Node2D:
	var result: Node2D
	var best: float = INF
	for enemy in enemies:
		if enemy.dead or enemy.spawn_protection > 0:
			continue
		var distance: float = player.position.distance_squared_to(enemy.position)
		if distance < best:
			best = distance
			result = enemy
	return result

func spawn_enemy(data: Resource, elite: int = 0, difficulty: float = 1.0) -> Node2D:
	var enemy = Enemy.new()
	enemy.setup(data, self, elite, difficulty)
	serial += 1
	enemy.serial = serial
	var area: Rect2 = ARENA.grow(-enemy.radius - 4)
	var edge: int = randi_range(0, 3)
	enemy.position = Vector2(randf_range(area.position.x, area.end.x), area.position.y if edge == 0 else area.end.y) if edge < 2 else Vector2(area.position.x if edge == 2 else area.end.x, randf_range(area.position.y, area.end.y))
	if enemy.position.distance_to(player.position) < 250:
		enemy.position = area.position + area.end - enemy.position
	if String(data.id).begins_with("boss_"):
		boss = enemy
		enemy.spawn_protection = 2.0
	add_child(enemy)
	if art != null:
		art.attach_enemy(enemy)
	enemies.append(enemy)
	return enemy

func take_damage(amount: int) -> void:
	if damage_time > 0 or health <= 0 or state != State.PLAYING:
		return
	health = maxf(0, health - maxi(1, amount - int(stats.armor)))
	damage_time = 0.7 + stats.grace
	player.hurt_time = damage_time
	sound.play("hurt")

func kill_enemy(enemy: Node2D) -> void:
	if enemy.dead:
		return
	enemy.dead = true
	kills += 1
	var enemy_id := String(enemy.spec.id)
	var xp_tier := 3 if enemy_id.begins_with("boss_") else (2 if enemy.elite >= 2 else (1 if enemy.elite == 1 else 0))
	var base_xp: int = int({"chaser": 3, "runner": 4, "charger": 5, "shooter": 6, "orbiter": 7}.get(enemy_id, 3))
	var xp_value: int = int(base_xp) + enemy.elite * 5 + (15 if enemy_id.begins_with("boss_") else 0)
	spawn_xp_orb(enemy.position, xp_value, xp_tier)
	spawn_gold_orb(enemy.position, 25 if enemy_id.begins_with("boss_") else 2 + enemy.elite * 2)
	health = minf(max_health, health + stats.siphon) if health > 0 else 0
	if String(enemy.spec.id).begins_with("boss_"):
		director.complete_boss()

func spawn_xp_orb(at: Vector2, amount: int, tier: int = 0) -> void:
	var orb := XPOrb.new()
	orb.position = at
	orb.setup(amount, player, tier)
	add_child(orb)
	xp_orbs.append(orb)

func spawn_gold_orb(at: Vector2, amount: int) -> void:
	var orb := GoldOrb.new()
	orb.position = at + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	orb.setup(amount, player)
	add_child(orb)
	gold_orbs.append(orb)

func gain_xp(amount: int) -> void:
	run_xp += maxi(1, amount)
	hud.show_pickup(amount)
	if run_xp < xp_to_next or state != State.PLAYING:
		return
	run_xp -= xp_to_next
	run_level += 1
	xp_to_next = 30 + run_level * 10
	if levelup_pending:
		return
	levelup_pending = true
	levelup_delay = 0.9
	player.show_level_up()
	sound.play("level_up")

func create_echo() -> void:
	sound.play("echo")
	hud.announce("replace_echo" if not echoes.is_empty() else "new_echo")
	if not echoes.is_empty():
		var oldest: Node = echoes.pop_front()
		oldest.queue_free()
	var echo = Echo.new()
	echo_serial += 1
	echo.setup(recorder.snapshot(), self, echo_serial)
	add_child(echo)
	if art != null:
		art.attach_echo(echo)
	echoes.append(echo)

func offer_upgrades() -> void:
	var pool: Array = []
	var weapon_pool: Array = []
	for item in Catalog.SECONDARY_WEAPONS:
		if int(secondary_weapons.get(item.weapon_id, 0)) < 5:
			weapon_pool.append(item)
	var preferred_weapons: Array = weapon_pool.filter(func(item: Resource) -> bool:
		return int(secondary_weapons.get(item.weapon_id, 0)) == 0) if secondary_weapons.size() < 3 else weapon_pool.filter(func(item: Resource) -> bool:
		return int(secondary_weapons.get(item.weapon_id, 0)) > 0)
	preferred_weapons.shuffle()
	pool.append_array(preferred_weapons.slice(0, mini(3, preferred_weapons.size())))
	if pool.size() < 3:
		var remaining_weapons: Array = weapon_pool.filter(func(item: Resource) -> bool: return item not in pool)
		remaining_weapons.shuffle()
		pool.append_array(remaining_weapons.slice(0, 3 - pool.size()))
	for item in Catalog.UPGRADES:
		if upgrade_counts.get(item.id, 0) < item.limit and (item.stat != "heal" or health < max_health):
			pool.append(item)
	if pool.size() < 3:
		pool.shuffle()
	offers = pool.slice(0, 3)
	if offers.is_empty():
		return
	state = State.UPGRADE
	get_tree().paused = true
	hud.show_upgrades(offers)

func apply_upgrade(index: int) -> void:
	if state != State.UPGRADE or index < 0 or index >= offers.size():
		return
	var item: Resource = offers[index]
	if item.core_type == "weapon":
		secondary_weapons[item.weapon_id] = mini(5, int(secondary_weapons.get(item.weapon_id, 0)) + 1)
		upgrade_counts[item.id] = secondary_weapons[item.weapon_id]
		offers = []
		state = State.PLAYING
		get_tree().paused = false
		hud.close_overlay()
		sound.play("upgrade")
		return
	else:
		upgrade_counts[item.id] = upgrade_counts.get(item.id, 0) + 1
	match item.stat:
		"max_hp":
			max_health += item.amount
			health = minf(max_health, health + item.amount)
		"heal": health = minf(max_health, health + item.amount)
		"speed": player.speed += item.amount
		"haste": stats.haste += 1
		_: stats[item.stat] += item.amount
	offers = []
	state = State.PLAYING
	get_tree().paused = false
	hud.close_overlay()
	sound.play("upgrade")

func finish(victory: bool) -> void:
	if state == State.ENDED:
		return
	won = victory
	state = State.ENDED
	player.active = false
	if not test_mode:
		profile.finish_run(won, run_time, kills)
	sound.play("win" if won else "lose")
	hud.show_result()

func _draw() -> void:
	if art != null:
		art.draw_projectiles(self)
	if combat == null:
		return
	draw_secondary_vfx()
	if art == null:
		for bullet in combat.friendly:
			draw_circle(bullet.position, 6 if bullet.ghost else 7, Color("91a5ff") if bullet.ghost else Color("ffe59c"))
		for bullet in combat.hostile:
			draw_circle(bullet.position, 10, Color("ff425b"))
			draw_arc(bullet.position, 12, 0, TAU, 12, Color("ffd0d5"), 2)
	for zone in combat.enemy_zones:
		var zone_age: float = float(zone.get("age", 0.0))
		var zone_delay: float = float(zone.get("delay", 0.7))
		var zone_radius: float = float(zone.get("radius", 80.0))
		var zone_ready: float = clampf(zone_age / zone_delay, 0.0, 1.0)
		var zone_color := Color("ffb347") if zone_ready < 1.0 else Color("d85cff")
		draw_circle(zone.position, zone_radius, Color(zone_color, 0.035 + zone_ready * 0.045))
		draw_arc(zone.position, zone_radius, -PI * 0.5, -PI * 0.5 + TAU * zone_ready, 28, Color(zone_color, 0.9), 4.0)
		draw_arc(zone.position, zone_radius * (0.35 + zone_ready * 0.65), 0, TAU, 24, Color(zone_color, 0.28), 2.0)
		if zone_ready >= 1.0:
			draw_circle(zone.position, 9.0 + sin(run_time * 14.0) * 2.0, Color(zone_color, 0.4))
	for effect in combat.effects:
		if effect.get("mine", false):
			var mine_age: float = float(effect.get("age", 0.0))
			var mine_alpha: float = 0.72 if effect.get("armed", false) else 0.36 + sin(mine_age * 12.0) * 0.16
			if effect.get("detonated", false):
				var blast_ratio: float = 1.0 - clampf(effect.life / 0.34, 0.0, 1.0)
				draw_circle(effect.position, float(effect.radius) * blast_ratio, Color(1.0, 0.35, 0.48, 0.16 * (1.0 - blast_ratio)))
				draw_arc(effect.position, float(effect.radius) * blast_ratio, 0, TAU, 32, Color("ffb0cb", 1.0 - blast_ratio), 5)
			else:
				draw_circle(effect.position, 12.0, Color("ff637d", mine_alpha))
				draw_arc(effect.position, float(effect.radius), 0, TAU, 24, Color("ff637d", mine_alpha * 0.8), 3)
				draw_arc(effect.position, 20.0 + sin(mine_age * 8.0) * 4.0, 0, TAU, 20, Color("ffd166", mine_alpha), 2)
		elif effect.get("orbit", false):
			draw_arc(effect.position, float(effect.radius), 0, TAU, 32, Color("b78cff", effect.life / 0.18), 7)
		elif effect.get("beam", false):
			var beam_alpha: float = clampf(effect.life / 0.16, 0.0, 1.0)
			draw_line(effect.position, effect.end, Color(0.33, 0.92, 0.84, beam_alpha * 0.20), 18)
			draw_line(effect.position, effect.end, Color("d7fff8", beam_alpha), 4)
			draw_circle(effect.end, 12.0 + (1.0 - beam_alpha) * 16.0, Color(0.33, 0.92, 0.84, beam_alpha * 0.45))
		elif effect.get("drone_fire", false):
			var fire_alpha: float = clampf(effect.life / 0.14, 0.0, 1.0)
			draw_line(effect.position, effect.end, Color(1.0, 0.82, 0.35, fire_alpha * 0.22), 12)
			draw_line(effect.position, effect.end, Color("fff1b0", fire_alpha), 3)
		else:
			draw_arc(effect.position, 12 + (0.18 - effect.life) * 150, 0, TAU, 12, Color(1, 0.85, 0.6, effect.life / 0.18), 3)

func draw_secondary_vfx() -> void:
	var now: float = run_time
	# Projectile silhouettes get a proper glow, directional trail and a distinct shape.
	for bullet in combat.friendly:
		var secondary_id: String = String(bullet.get("secondary_id", ""))
		if secondary_id == "":
			continue
		var direction: Vector2 = bullet.velocity.normalized()
		var side: Vector2 = Vector2(-direction.y, direction.x)
		var pulse: float = 0.82 + sin(now * 18.0 + bullet.position.x * 0.01) * 0.18
		if secondary_id == "boomerang":
			for trail_index in range(4):
				var trail_pos: Vector2 = bullet.position - direction * (trail_index + 1) * 14.0
				draw_circle(trail_pos, 10.0 - trail_index * 1.7, Color(0.33, 0.92, 0.84, 0.16 - trail_index * 0.03))
			draw_colored_polygon(PackedVector2Array([bullet.position + direction * 16.0, bullet.position + side * 7.0, bullet.position - direction * 12.0, bullet.position - side * 7.0]), Color("bffff5", pulse))
			draw_line(bullet.position - side * 5.0, bullet.position + direction * 12.0 + side * 4.0, Color("55ebd2"), 3.0)
		elif secondary_id == "drone":
			for trail_index in range(3):
				draw_circle(bullet.position - direction * trail_index * 11.0, 7.0 - trail_index * 1.5, Color(1.0, 0.82, 0.35, 0.22 - trail_index * 0.05))
			draw_circle(bullet.position, 9.0, Color("ffd166", 0.28))
			draw_colored_polygon(PackedVector2Array([bullet.position + direction * 12.0, bullet.position + side * 6.0, bullet.position - direction * 8.0, bullet.position - side * 6.0]), Color("fff1b0"))
	# Orbit blades are persistent animated objects, not just a damage ring.
	var orbit_level: int = int(secondary_weapons.get("orbit", 0))
	if orbit_level > 0:
		var orbit_radius: float = 82.0 + orbit_level * 12.0
		var blade_count: int = 2 + int(orbit_level / 2)
		for blade_index in range(blade_count):
			var angle: float = now * (1.8 + orbit_level * 0.12) + TAU * blade_index / blade_count
			var blade_pos: Vector2 = player.position + Vector2.from_angle(angle) * orbit_radius
			var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
			draw_circle(blade_pos, 17.0, Color(0.72, 0.55, 1.0, 0.10))
			draw_colored_polygon(PackedVector2Array([blade_pos + tangent * 13.0, blade_pos + Vector2.from_angle(angle) * 9.0, blade_pos - tangent * 13.0, blade_pos - Vector2.from_angle(angle) * 9.0]), Color("d9c5ff"))
			draw_line(blade_pos - tangent * 8.0, blade_pos + tangent * 8.0, Color("b78cff"), 3.0)
		draw_arc(player.position, orbit_radius, now, now + PI * 0.65, 20, Color(0.72, 0.55, 1.0, 0.25), 2.0)
	# The drone has a visible companion chassis and a soft lock-on tether.
	var drone_level: int = int(secondary_weapons.get("drone", 0))
	if drone_level > 0:
		var drone_angle: float = now * 1.35
		var drone_pos: Vector2 = player.position + Vector2.from_angle(drone_angle) * (54.0 + drone_level * 3.0) + Vector2(0, -18)
		draw_circle(drone_pos, 25.0, Color(1.0, 0.82, 0.35, 0.08))
		draw_arc(drone_pos, 17.0, drone_angle, drone_angle + PI * 1.5, 20, Color("ffd166", 0.9), 3.0)
		draw_colored_polygon(PackedVector2Array([drone_pos + Vector2(0, -11), drone_pos + Vector2(13, 8), drone_pos, drone_pos + Vector2(-13, 8)]), Color("ffe8a3"))
		draw_circle(drone_pos + Vector2(0, -2), 4.0 + sin(now * 10.0) * 1.2, Color("fff8d6"))
		var drone_target: Node2D = nearest_enemy()
		if drone_target != null:
			var lock_pulse: float = 0.75 + sin(now * 12.0) * 0.25
			draw_dashed_line(drone_pos, drone_target.position, Color(1.0, 0.82, 0.35, 0.30), 2.0, 8.0)
			draw_arc(drone_target.position, 28.0 + sin(now * 8.0) * 3.0, 0, TAU, 24, Color(1.0, 0.82, 0.35, lock_pulse), 2.0)
			draw_line(drone_target.position - Vector2(38, 0), drone_target.position - Vector2(22, 0), Color("ffd166", lock_pulse), 2.0)
			draw_line(drone_target.position + Vector2(22, 0), drone_target.position + Vector2(38, 0), Color("ffd166", lock_pulse), 2.0)
