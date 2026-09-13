extends Node2D

const Catalog = preload("res://scripts/data/catalog.gd")
const Recorder = preload("res://scripts/core/recorder.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Director = preload("res://scripts/core/director.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Echo = preload("res://scripts/echo.gd")
const XPOrb = preload("res://scripts/xp_orb.gd")
const ArtBridge = preload("res://scripts/visuals/art_bridge.gd")
const SoundBank = preload("res://scripts/sound_bank.gd")
const ARENA: Rect2 = Rect2(50, 310, 980, 1510)
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
var echoes: Array = []
var upgrade_counts: Dictionary = {}
var offers: Array = []
var stats: Dictionary = {"damage": 0.0, "haste": 0, "pellets": 0, "pierce": 0, "bullet_speed": 0.0, "lifetime": 0.0, "armor": 0, "regen": 0, "echo_power": 0.0, "crit": 0.0, "siphon": 0, "grace": 0.0}
var run_level: int = 1
var run_xp: int = 0
var xp_to_next: int = 18
var health: float = 100
var max_health: float = 100
var damage_time: float = 0
var kills: int = 0
var run_tick: int = 0
var run_time: float = 0
var next_upgrade_tick: int = 1800
var won: bool = false
var practice: bool = false
var reduced_effects: bool = false
var serial: int = 0
var echo_serial: int = 0
var boss: Node2D
var boss_killed: bool = false
var test_mode: bool = false

func _ready() -> void:
	profile = get_node("/root/Profile")
	practice = profile.practice
	weapon = Catalog.WEAPONS[clampi(profile.selected_weapon, 0, 2)]
	# Current vertical slice deliberately ships one hero and one arena.
	map_data = Catalog.MAPS[0]
	sound = SoundBank.new()
	add_child(sound)
	combat = Combat.new(self)
	director = Director.new(self)
	player.arena = ARENA
	player.configure_character(0)
	player.configure_equipment(profile.data.equipment)
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
		echo.tint = [Color("86a8ff"), Color("ffd166"), Color("ee9bfa")][profile.data.palette]

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
	for echo in echoes:
		echo.advance()
		art.update_echo(echo)
	var fired: Array = combat.fire(nearest_enemy(), delta)
	if recorder.record(player.position, fired):
		create_echo()
		recorder.begin(player.position)
	combat.advance(delta)
	for enemy in enemies:
		if not enemy.dead and enemy.spawn_protection <= 0 and enemy.position.distance_to(player.position) < enemy.radius + 25:
			take_damage(enemy.contact_damage)
	for index in range(enemies.size() - 1, -1, -1):
		if enemies[index].dead:
			enemies[index].queue_free()
			enemies.remove_at(index)
	if health <= 0:
		finish(false)
	elif (practice and run_tick >= 18000) or (not practice and boss_killed):
		finish(true)
	elif run_tick >= 54000:
		finish(false)
	elif run_tick >= next_upgrade_tick and run_level == 1:
		# Guarantee the first choice even when a short run has few enemies.
		next_upgrade_tick += 1800
		offer_upgrades()
	hud.refresh()
	queue_redraw()

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
	spawn_xp_orb(enemy.position, 5 + enemy.elite * 4 + (12 if String(enemy.spec.id).begins_with("boss_") else 0))
	health = minf(max_health, health + stats.siphon) if health > 0 else 0
	if String(enemy.spec.id).begins_with("boss_"):
		director.complete_boss()

func spawn_xp_orb(at: Vector2, amount: int) -> void:
	var orb := XPOrb.new()
	orb.position = at
	orb.setup(amount, player)
	add_child(orb)
	xp_orbs.append(orb)

func gain_xp(amount: int) -> void:
	run_xp += maxi(1, amount)
	hud.show_pickup(amount)
	if run_xp < xp_to_next or state != State.PLAYING:
		return
	run_xp -= xp_to_next
	run_level += 1
	xp_to_next = 18 + run_level * 7
	offer_upgrades()

func create_echo() -> void:
	sound.play("echo")
	hud.announce("replace_echo" if echoes.size() == 4 else "new_echo")
	if echoes.size() == 4:
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
	for item in Catalog.UPGRADES:
		if upgrade_counts.get(item.id, 0) < item.limit and (item.stat != "heal" or health < max_health):
			pool.append(item)
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
	draw_rect(ARENA, Color("111c30"))
	var map_accent: Color = map_data.accent if map_data != null else Color("62eacb")
	for x in range(100, 1030, 100):
		draw_line(Vector2(x, 310), Vector2(x, 1820), Color(map_accent, 0.10), 1)
	for y in range(400, 1820, 100):
		draw_line(Vector2(50, y), Vector2(1030, y), Color(map_accent, 0.10), 1)
	for corner in [ARENA.position, Vector2(ARENA.end.x, ARENA.position.y), Vector2(ARENA.position.x, ARENA.end.y), ARENA.end]:
		draw_circle(corner, 18, Color(map_accent, 0.16))
	draw_rect(ARENA, Color(map_accent, 0.72), false, 5)
	if art != null:
		art.draw_projectiles(self)
	if combat == null:
		return
	if art == null:
		for bullet in combat.friendly:
			draw_circle(bullet.position, 6 if bullet.ghost else 7, Color("91a5ff") if bullet.ghost else Color("ffe59c"))
		for bullet in combat.hostile:
			draw_circle(bullet.position, 10, Color("ff425b"))
			draw_arc(bullet.position, 12, 0, TAU, 12, Color("ffd0d5"), 2)
	for effect in combat.effects:
		draw_arc(effect.position, 12 + (0.18 - effect.life) * 150, 0, TAU, 12, Color(1, 0.85, 0.6, effect.life / 0.18), 3)
