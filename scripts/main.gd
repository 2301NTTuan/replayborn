extends Node2D

const Catalog = preload("res://scripts/data/catalog.gd")
const Recorder = preload("res://scripts/core/recorder.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Director = preload("res://scripts/core/director.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Echo = preload("res://scripts/echo.gd")
const XPOrb = preload("res://scripts/xp_orb.gd")
const GoldOrb = preload("res://scripts/gold_orb.gd")
const FieldPickup = preload("res://scripts/field_pickup.gd")
const ArtBridge = preload("res://scripts/visuals/art_bridge.gd")
const SoundBank = preload("res://scripts/sound_bank.gd")
const ARENA: Rect2 = Rect2(-220, 120, 1520, 1980)
# This protects the whole player silhouette (marker, head and weapon), rather
# than only the collision center, when the camera reaches the north boundary.
const TOP_UI_SAFE_SPACE: int = 270
const MAX_XP_ORBS: int = 90
const MAX_GOLD_ORBS: int = 48
const MAX_FIELD_PICKUPS: int = 20
const DRAW_EVERY_TICKS: int = 2
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
var field_pickups: Array = []
var game_camera: Camera2D

func dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func draw_glow_disc(center: Vector2, radius: float, color: Color, rings: int = 4) -> void:
	for ring in range(rings, 0, -1):
		var ratio: float = float(ring) / float(rings)
		draw_circle(center, radius * ratio, Color(color, color.a * 0.18 * (1.0 - ratio * 0.55)))
	draw_circle(center, radius * 0.28, Color(color, minf(1.0, color.a * 1.25)))

func draw_energy_flare(center: Vector2, radius: float, color: Color, spokes: int, phase: float) -> void:
	draw_glow_disc(center, radius * 0.55, Color(color, color.a * 0.45), 3)
	for spoke in range(spokes):
		var angle: float = phase + TAU * spoke / spokes
		var inner: Vector2 = center + Vector2.from_angle(angle) * radius * 0.22
		var outer: Vector2 = center + Vector2.from_angle(angle) * radius
		draw_line(inner, outer, Color(color, color.a * 0.76), 2.0)

func draw_blade_projectile(center: Vector2, direction: Vector2, side: Vector2, phase: float) -> void:
	var wing: float = 1.0 + sin(phase) * 0.16
	draw_glow_disc(center, 28.0, Color(0.25, 1.0, 0.88, 0.42), 4)
	for trail_index in range(6):
		var trail_pos: Vector2 = center - direction * (trail_index + 1) * 13.0
		var trail_alpha: float = 0.24 - trail_index * 0.032
		draw_circle(trail_pos, 13.0 - trail_index * 1.35, Color(0.25, 1.0, 0.88, trail_alpha))
		draw_line(trail_pos - side * 6.0, trail_pos + side * 6.0, Color(0.75, 1.0, 0.95, trail_alpha * 0.7), 2.0)
	draw_colored_polygon(PackedVector2Array([
		center + direction * 18.0,
		center + side * 16.0 * wing,
		center - direction * 3.0,
		center - side * 16.0 * wing
	]), Color("bffff5"))
	draw_colored_polygon(PackedVector2Array([
		center - direction * 2.0,
		center + side * 7.0,
		center - direction * 17.0,
		center - side * 7.0
	]), Color("49d8ff", 0.86))
	draw_line(center - side * 12.0, center + side * 12.0, Color("ffffff", 0.82), 2.0)

func draw_drone_bolt(center: Vector2, direction: Vector2, side: Vector2, phase: float) -> void:
	draw_glow_disc(center, 21.0, Color(1.0, 0.78, 0.18, 0.36), 4)
	for trail_index in range(5):
		var trail_pos: Vector2 = center - direction * trail_index * 12.0
		draw_circle(trail_pos, 9.0 - trail_index * 1.15, Color(1.0, 0.74, 0.18, 0.24 - trail_index * 0.036))
	var jitter: float = sin(phase * 2.3) * 3.0
	draw_colored_polygon(PackedVector2Array([
		center + direction * 15.0,
		center + side * (7.0 + jitter),
		center - direction * 11.0,
		center - side * (7.0 - jitter)
	]), Color("fff1b0"))
	draw_line(center - direction * 15.0, center + direction * 17.0, Color("ffffff", 0.86), 2.2)

func draw_attack_drone(center: Vector2, direction: Vector2, side: Vector2, level: int, phase: float, simplified: bool) -> void:
	var glow_alpha: float = 0.20 if simplified else 0.36
	draw_glow_disc(center, 20.0 + level, Color(1.0, 0.78, 0.18, glow_alpha), 2 if simplified else 4)
	draw_circle(center + Vector2(0, 7), 10.0, Color(0.0, 0.0, 0.0, 0.30))
	var wing: float = 9.0 + sin(phase * 11.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		center + direction * 14.0,
		center + side * wing - direction * 3.0,
		center - direction * 11.0,
		center - side * wing - direction * 3.0
	]), Color("5d4521"))
	draw_line(center - side * (wing + 5.0), center + side * (wing + 5.0), Color("ffd166", 0.72), 2.0)
	draw_circle(center + direction * 3.0, 4.5, Color("fff7cb"))
	draw_line(center - direction * 14.0, center - direction * 27.0, Color(1.0, 0.64, 0.12, 0.42), 3.0)

func visual_load_high() -> bool:
	return reduced_effects or enemies.size() > 44 or combat.friendly.size() > 170 or combat.effects.size() > 44

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
	player.game = self
	setup_camera()
	player.configure_character(0)
	player.configure_equipment(profile.data.equipment)
	var meta: Dictionary = profile.data.meta_upgrades
	max_health += int(dict_value(meta, "hp", 0)) * 15
	health = max_health
	stats.damage = int(dict_value(meta, "damage", 0)) * 0.05
	stats.armor = int(dict_value(meta, "armor", 0))
	stats.haste = int(dict_value(meta, "haste", 0))
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

func setup_camera() -> void:
	game_camera = Camera2D.new()
	game_camera.name = "RunCamera"
	game_camera.enabled = true
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 7.5
	game_camera.limit_left = int(ARENA.position.x)
	game_camera.limit_top = int(ARENA.position.y - TOP_UI_SAFE_SPACE)
	game_camera.limit_right = int(ARENA.end.x)
	game_camera.limit_bottom = int(ARENA.end.y)
	game_camera.position = player.position
	add_child(game_camera)

func apply_settings() -> void:
	reduced_effects = profile.data.reduced
	player.reduced_effects = reduced_effects
	sound.set_levels(profile.data.volume, profile.data.music)
	if combat != null and reduced_effects:
		combat.effects.clear()
	for echo in echoes:
		echo.tint = [Color("ff4fd8"), Color("ffd166"), Color("63f6ff"), Color("a78bfa")][(echo.number - 1) % 4]

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
	profile.save_profile()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and state == State.PLAYING:
		toggle_pause()
		profile.save_profile()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if state == State.PLAYING:
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
	if game_camera != null:
		game_camera.position = player.position
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
				profile.add_rewards(gold.value, 0, "", 0, false)
				hud.show_pickup(gold.value, true)
			gold.queue_free()
			gold_orbs.remove_at(index)
	for index in range(field_pickups.size() - 1, -1, -1):
		var pickup: Node2D = field_pickups[index]
		if pickup.advance(delta):
			if pickup.collected:
				collect_field_pickup(pickup.kind)
			pickup.queue_free()
			field_pickups.remove_at(index)
	for index in range(echoes.size() - 1, -1, -1):
		var echo = echoes[index]
		if echo.dead or echo.advance():
			echo.queue_free()
			echoes.remove_at(index)
		else:
			art.update_echo(echo)
	var fired: Array = combat.fire(nearest_enemy(), delta)
	# Each 15-second tape becomes an independent Echo; existing tapes loop.
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
	elif (practice and run_tick >= 18000) or (not practice and boss_killed):
		finish(true)
	elif run_tick >= 180000:
		finish(false)
	hud.refresh()
	if run_tick % DRAW_EVERY_TICKS == 0:
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
	if enemy.position.distance_to(player.position) < 390:
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
	var base_xp: int = int(dict_value({"chaser": 3, "runner": 4, "charger": 5, "shooter": 6, "orbiter": 7}, enemy_id, 3))
	var xp_value: int = int(base_xp) + enemy.elite * 5 + (15 if enemy_id.begins_with("boss_") else 0)
	spawn_xp_orb(enemy.position, xp_value, xp_tier)
	spawn_gold_orb(enemy.position, 25 if enemy_id.begins_with("boss_") else 2 + enemy.elite * 2)
	roll_field_drop(enemy.position, enemy_id.begins_with("boss_"))
	health = minf(max_health, health + stats.siphon) if health > 0 else 0
	if String(enemy.spec.id).begins_with("boss_"):
		director.complete_boss()

func spawn_xp_orb(at: Vector2, amount: int, tier: int = 0) -> void:
	if xp_orbs.size() >= MAX_XP_ORBS:
		var nearest: Node2D = null
		var best: float = INF
		for existing: Node2D in xp_orbs:
			var distance: float = existing.position.distance_squared_to(at)
			if distance < best:
				best = distance
				nearest = existing
		if nearest != null:
			nearest.value += amount
			nearest.tier = maxi(nearest.tier, tier)
			nearest.queue_redraw()
			return
	var orb := XPOrb.new()
	orb.position = at
	orb.setup(amount, player, tier)
	add_child(orb)
	xp_orbs.append(orb)

func spawn_gold_orb(at: Vector2, amount: int) -> void:
	if gold_orbs.size() >= MAX_GOLD_ORBS:
		if not gold_orbs.is_empty():
			gold_orbs[0].value += amount
			gold_orbs[0].queue_redraw()
		return
	var orb := GoldOrb.new()
	orb.position = at + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	orb.setup(amount, player)
	add_child(orb)
	gold_orbs.append(orb)

func roll_field_drop(at: Vector2, boss_drop: bool) -> void:
	# Rare field drops break up the collection loop without flooding the arena.
	var magnet_chance: float = 0.24 if boss_drop else 0.035
	var heart_chance: float = 0.32 if boss_drop else (0.055 if health < max_health * 0.82 else 0.018)
	if randf() < magnet_chance:
		spawn_field_pickup(at, "magnet")
	elif randf() < heart_chance:
		spawn_field_pickup(at, "heart")

func spawn_field_pickup(at: Vector2, kind: String) -> void:
	if field_pickups.size() >= MAX_FIELD_PICKUPS:
		field_pickups[0].queue_free()
		field_pickups.remove_at(0)
	var pickup := FieldPickup.new()
	pickup.position = at + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
	pickup.setup(kind, player)
	add_child(pickup)
	field_pickups.append(pickup)

func collect_field_pickup(kind: String) -> void:
	if kind == "magnet":
		for orb in xp_orbs:
			if is_instance_valid(orb) and orb.position.distance_to(player.position) <= 480.0:
				orb.magnetize()
		for gold in gold_orbs:
			if is_instance_valid(gold) and gold.position.distance_to(player.position) <= 480.0:
				gold.magnetize()
		combat.add_effect({"position": player.position, "life": 0.42, "magnet_pickup": true, "radius": 480.0})
	else:
		health = minf(max_health, health + maxf(16.0, max_health * 0.22))
		combat.add_effect({"position": player.position, "life": 0.34, "heart_pickup": true})

func enemy_durability_multiplier() -> float:
	var weapon_levels: int = 0
	for level in secondary_weapons.values():
		weapon_levels += int(level)
	return 1.30 + secondary_weapons.size() * 0.16 + weapon_levels * 0.07

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
	hud.announce("replace_echo" if echoes.size() >= 4 else "new_echo")
	if echoes.size() >= 4:
		var oldest: Node = echoes.pop_front()
		if is_instance_valid(oldest):
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
		if int(dict_value(secondary_weapons, item.weapon_id, 0)) < 5:
			weapon_pool.append(item)
	var preferred_weapons: Array = weapon_pool.filter(func(item: Resource) -> bool:
		return int(dict_value(secondary_weapons, item.weapon_id, 0)) == 0) if secondary_weapons.size() < 3 else weapon_pool.filter(func(item: Resource) -> bool:
		return int(dict_value(secondary_weapons, item.weapon_id, 0)) > 0)
	preferred_weapons.shuffle()
	pool.append_array(preferred_weapons.slice(0, mini(3, preferred_weapons.size())))
	if pool.size() < 3:
		var remaining_weapons: Array = weapon_pool.filter(func(item: Resource) -> bool: return item not in pool)
		remaining_weapons.shuffle()
		pool.append_array(remaining_weapons.slice(0, 3 - pool.size()))
	for item in Catalog.UPGRADES:
		if int(dict_value(upgrade_counts, item.id, 0)) < item.limit and (item.stat != "heal" or health < max_health):
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
		secondary_weapons[item.weapon_id] = mini(5, int(dict_value(secondary_weapons, item.weapon_id, 0)) + 1)
		upgrade_counts[item.id] = secondary_weapons[item.weapon_id]
		offers = []
		state = State.PLAYING
		get_tree().paused = false
		hud.close_overlay()
		sound.play("upgrade")
		return
	else:
		upgrade_counts[item.id] = int(dict_value(upgrade_counts, item.id, 0)) + 1
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
		if visual_load_high() and zone.age < float(zone.delay) * 0.35:
			continue
		var zone_age: float = float(dict_value(zone, "age", 0.0))
		var zone_delay: float = float(dict_value(zone, "delay", 0.7))
		var zone_radius: float = float(dict_value(zone, "radius", 80.0))
		var zone_ready: float = clampf(zone_age / zone_delay, 0.0, 1.0)
		var zone_color := Color("ffb347") if zone_ready < 1.0 else Color("d85cff")
		draw_circle(zone.position, zone_radius, Color(zone_color, 0.035 + zone_ready * 0.045))
		draw_arc(zone.position, zone_radius, -PI * 0.5, -PI * 0.5 + TAU * zone_ready, 28, Color(zone_color, 0.9), 4.0)
		draw_arc(zone.position, zone_radius * (0.35 + zone_ready * 0.65), 0, TAU, 24, Color(zone_color, 0.28), 2.0)
		if zone_ready >= 1.0:
			draw_circle(zone.position, 9.0 + sin(run_time * 14.0) * 2.0, Color(zone_color, 0.4))
	for effect in combat.effects:
		if bool(dict_value(effect, "mine", false)):
			var mine_age: float = float(dict_value(effect, "age", 0.0))
			var mine_armed: bool = bool(dict_value(effect, "armed", false))
			var mine_alpha: float = 0.82 if mine_armed else 0.40 + sin(mine_age * 12.0) * 0.16
			if bool(dict_value(effect, "detonated", false)):
				var blast_ratio: float = 1.0 - clampf(effect.life / 0.34, 0.0, 1.0)
				var blast_radius: float = float(effect.radius) * blast_ratio
				draw_glow_disc(effect.position, blast_radius * 0.72, Color(1.0, 0.24, 0.38, 0.34 * (1.0 - blast_ratio)), 5)
				draw_arc(effect.position, blast_radius, 0, TAU, 40, Color("ffb0cb", 1.0 - blast_ratio), 6)
				draw_arc(effect.position, blast_radius * 0.62, run_time * 7.0, run_time * 7.0 + PI * 1.35, 24, Color("ffd166", 0.8 * (1.0 - blast_ratio)), 4)
				draw_energy_flare(effect.position, 26.0 + blast_radius * 0.22, Color(1.0, 0.88, 0.45, 0.78 * (1.0 - blast_ratio)), 9, run_time * 3.0)
			else:
				var mine_color := Color("ff637d") if mine_armed else Color("ffd166")
				draw_circle(effect.position + Vector2(0, 10), 17.0, Color(0.0, 0.0, 0.0, 0.24))
				draw_glow_disc(effect.position, 28.0, Color(mine_color, 0.28), 4)
				draw_colored_polygon(PackedVector2Array([
					effect.position + Vector2(0, -16),
					effect.position + Vector2(16, -3),
					effect.position + Vector2(10, 15),
					effect.position + Vector2(-10, 15),
					effect.position + Vector2(-16, -3)
				]), Color("2a2030"))
				draw_arc(effect.position, 13.0, 0, TAU, 18, Color(mine_color, mine_alpha), 4.0)
				draw_circle(effect.position, 5.5 + sin(mine_age * 18.0) * 1.3, Color("fff1b0", mine_alpha))
				draw_arc(effect.position, float(effect.radius), -PI * 0.5, -PI * 0.5 + TAU * clampf(mine_age / 2.0, 0.0, 1.0), 36, Color("ff637d", mine_alpha * 0.82), 3.5)
				draw_arc(effect.position, float(effect.radius) * 0.72, run_time * 2.0, run_time * 2.0 + PI * 0.9, 20, Color("ffd166", mine_alpha * 0.42), 2.0)
		elif bool(dict_value(effect, "orbit", false)):
			var orbit_alpha: float = clampf(effect.life / 0.18, 0.0, 1.0)
			draw_arc(effect.position, float(effect.radius), run_time * 7.0, run_time * 7.0 + TAU * 0.82, 42, Color("b78cff", orbit_alpha * 0.9), 8)
			draw_arc(effect.position, float(effect.radius) * 0.86, -run_time * 5.0, -run_time * 5.0 + TAU * 0.52, 30, Color("f0d7ff", orbit_alpha * 0.45), 3)
			draw_glow_disc(effect.position, float(effect.radius) * 0.25, Color(0.72, 0.55, 1.0, orbit_alpha * 0.10), 3)
		elif bool(dict_value(effect, "beam", false)):
			var beam_alpha: float = clampf(effect.life / 0.16, 0.0, 1.0)
			var beam_dir: Vector2 = effect.position.direction_to(effect.end)
			var beam_side: Vector2 = Vector2(-beam_dir.y, beam_dir.x)
			draw_line(effect.position - beam_side * 5.0, effect.end - beam_side * 5.0, Color(0.12, 0.66, 1.0, beam_alpha * 0.16), 17)
			draw_line(effect.position + beam_side * 5.0, effect.end + beam_side * 5.0, Color(0.33, 0.92, 0.84, beam_alpha * 0.22), 17)
			draw_line(effect.position, effect.end, Color(0.33, 0.92, 0.84, beam_alpha * 0.46), 10)
			draw_line(effect.position, effect.end, Color("d7fff8", beam_alpha), 3.5)
			draw_energy_flare(effect.position, 26.0, Color(0.33, 0.92, 0.84, beam_alpha * 0.85), 8, run_time * 8.0)
			draw_energy_flare(effect.end, 36.0 + (1.0 - beam_alpha) * 18.0, Color(0.33, 0.92, 0.84, beam_alpha), 10, -run_time * 7.0)
		elif bool(dict_value(effect, "drone_burst", false)):
			var burst_alpha: float = clampf(effect.life / 0.32, 0.0, 1.0)
			var burst_radius: float = float(effect.radius) * (1.0 - burst_alpha * 0.25)
			draw_glow_disc(effect.position, burst_radius * 0.82, Color(1.0, 0.48, 0.12, burst_alpha * 0.34), 5)
			draw_arc(effect.position, burst_radius, run_time * 8.0, run_time * 8.0 + TAU * 0.84, 30, Color("ffe49a", burst_alpha), 4.0)
			draw_energy_flare(effect.position, burst_radius * 0.56, Color(1.0, 0.76, 0.25, burst_alpha), 8, run_time * 10.0)
		elif bool(dict_value(effect, "drone_launch", false)):
			var launch_alpha: float = clampf(effect.life / 0.12, 0.0, 1.0)
			draw_energy_flare(effect.position, 18.0, Color(1.0, 0.82, 0.35, launch_alpha), 6, run_time * 12.0)
		elif bool(dict_value(effect, "magnet_pickup", false)):
			var magnet_alpha: float = clampf(effect.life / 0.42, 0.0, 1.0)
			draw_arc(effect.position, float(effect.radius) * (1.0 - magnet_alpha * 0.35), 0.0, TAU, 44, Color("76e9ff", magnet_alpha * 0.54), 3.0)
		elif bool(dict_value(effect, "heart_pickup", false)):
			draw_energy_flare(effect.position, 42.0, Color(1.0, 0.38, 0.54, clampf(effect.life / 0.34, 0.0, 1.0)), 7, run_time * 6.0)
		else:
			var hit_alpha: float = clampf(effect.life / 0.18, 0.0, 1.0)
			draw_energy_flare(effect.position, 16.0 + (0.18 - effect.life) * 110, Color(1.0, 0.85, 0.6, hit_alpha), 7, run_time * 9.0)

func draw_secondary_vfx() -> void:
	var now: float = run_time
	var high_load := visual_load_high()
	# Projectile silhouettes get a proper glow, directional trail and a distinct shape.
	var projectile_drawn: int = 0
	var projectile_limit := 42 if high_load else 120
	for index in range(combat.friendly.size() - 1, -1, -1):
		if projectile_drawn >= projectile_limit:
			break
		var bullet: Dictionary = combat.friendly[index]
		var secondary_id: String = String(dict_value(bullet, "secondary_id", ""))
		if secondary_id == "":
			continue
		var direction: Vector2 = bullet.velocity.normalized()
		var side: Vector2 = Vector2(-direction.y, direction.x)
		var pulse: float = 0.82 + sin(now * 18.0 + bullet.position.x * 0.01) * 0.18
		if secondary_id == "boomerang":
			if high_load:
				draw_glow_disc(bullet.position, 18.0, Color(0.25, 1.0, 0.88, 0.24), 2)
				draw_colored_polygon(PackedVector2Array([bullet.position + direction * 15.0, bullet.position + side * 11.0, bullet.position - direction * 11.0, bullet.position - side * 11.0]), Color("bffff5", 0.88))
			else:
				draw_blade_projectile(bullet.position, direction, side, now * 16.0 + bullet.position.length() * 0.01)
		elif secondary_id == "drone":
			draw_attack_drone(bullet.position, direction, side, int(dict_value(bullet, "drone_level", 1)), now + bullet.position.x * 0.002, high_load)
		projectile_drawn += 1
	# Orbit blades are persistent animated objects, not just a damage ring.
	var orbit_level: int = int(dict_value(secondary_weapons, "orbit", 0))
	if orbit_level > 0:
		var orbit_radius: float = 82.0 + orbit_level * 12.0
		var blade_count: int = 2 + int(orbit_level / 2)
		for blade_index in range(blade_count):
			var angle: float = now * (1.8 + orbit_level * 0.12) + TAU * blade_index / blade_count
			var blade_pos: Vector2 = player.position + Vector2.from_angle(angle) * orbit_radius
			var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
			draw_glow_disc(blade_pos, 18.0 if high_load else 22.0, Color(0.72, 0.55, 1.0, 0.20 if high_load else 0.28), 2 if high_load else 3)
			draw_colored_polygon(PackedVector2Array([blade_pos + tangent * 13.0, blade_pos + Vector2.from_angle(angle) * 9.0, blade_pos - tangent * 13.0, blade_pos - Vector2.from_angle(angle) * 9.0]), Color("d9c5ff"))
			draw_line(blade_pos - tangent * 10.0, blade_pos + tangent * 10.0, Color("ffffff", 0.78), 2.0)
			draw_line(blade_pos - Vector2.from_angle(angle) * 7.0, blade_pos + Vector2.from_angle(angle) * 7.0, Color("b78cff"), 3.0)
		if not high_load:
			draw_arc(player.position, orbit_radius, now, now + PI * 0.85, 26, Color(0.72, 0.55, 1.0, 0.30), 3.0)
			draw_arc(player.position, orbit_radius * 0.92, -now * 1.4, -now * 1.4 + PI * 0.55, 18, Color("f0d7ff", 0.18), 2.0)
	# The drone has a visible companion chassis and a soft lock-on tether.
	var drone_level: int = int(dict_value(secondary_weapons, "drone", 0))
	if drone_level > 0:
		var drone_angle: float = now * 1.35
		var drone_pos: Vector2 = player.position + Vector2.from_angle(drone_angle) * (54.0 + drone_level * 3.0) + Vector2(0, -18)
		draw_circle(drone_pos + Vector2(0, 9), 16.0, Color(0.0, 0.0, 0.0, 0.22))
		draw_glow_disc(drone_pos, 24.0, Color(1.0, 0.82, 0.35, 0.16 if high_load else 0.22), 2 if high_load else 4)
		draw_arc(drone_pos, 17.0, drone_angle, drone_angle + PI * 1.5, 20, Color("ffd166", 0.9), 3.0)
		draw_colored_polygon(PackedVector2Array([
			drone_pos + Vector2(0, -13),
			drone_pos + Vector2(15, 4),
			drone_pos + Vector2(8, 13),
			drone_pos + Vector2(-8, 13),
			drone_pos + Vector2(-15, 4)
		]), Color("4b3a20"))
		draw_colored_polygon(PackedVector2Array([drone_pos + Vector2(0, -10), drone_pos + Vector2(11, 6), drone_pos, drone_pos + Vector2(-11, 6)]), Color("ffe8a3"))
		draw_circle(drone_pos + Vector2(0, -2), 4.0 + sin(now * 10.0) * 1.2, Color("fff8d6"))
		draw_line(drone_pos + Vector2(-18, 1), drone_pos + Vector2(-30, -4 + sin(now * 12.0) * 2.0), Color("ffd166", 0.72), 2.5)
		draw_line(drone_pos + Vector2(18, 1), drone_pos + Vector2(30, -4 - sin(now * 12.0) * 2.0), Color("ffd166", 0.72), 2.5)
		var drone_target: Node2D = nearest_enemy()
		if drone_target != null:
			var lock_pulse: float = 0.75 + sin(now * 12.0) * 0.25
			if not high_load:
				draw_dashed_line(drone_pos, drone_target.position, Color(1.0, 0.82, 0.35, 0.38), 2.2, 7.0)
			draw_arc(drone_target.position, 30.0 + sin(now * 8.0) * 3.0, 0, TAU, 30, Color(1.0, 0.82, 0.35, lock_pulse), 2.4)
			if not high_load:
				draw_arc(drone_target.position, 20.0 + sin(now * 11.0) * 2.0, PI, PI * 2.0, 18, Color("fff1b0", lock_pulse * 0.72), 2.0)
				draw_line(drone_target.position - Vector2(38, 0), drone_target.position - Vector2(22, 0), Color("ffd166", lock_pulse), 2.0)
				draw_line(drone_target.position + Vector2(22, 0), drone_target.position + Vector2(38, 0), Color("ffd166", lock_pulse), 2.0)
