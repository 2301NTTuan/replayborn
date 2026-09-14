extends CharacterBody2D

var arena: Rect2 = Rect2(50, 310, 980, 1510)
var active: bool = true
var touch_direction: Vector2 = Vector2.ZERO
var speed: float = 420.0
var hurt_time: float = 0.0
var reduced_effects: bool = false
var character_index: int = 0
var gender: int = 0
var archetype: int = 0
var accent: Color = Color("62eacb")
var skin: Color = Color("f2b58f")
var hair: Color = Color("26344f")
var pulse: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var smoothed_direction: Vector2 = Vector2.ZERO
var shoot_flash: float = 0.0
var level_up_time: float = 0.0
var equipment: Dictionary = {}
var rarity_colors: Array[Color] = [Color("b8c3d1"), Color("65b7ff"), Color("c77dff"), Color("ff70c8"), Color("ffd166")]

func dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func configure_character(index: int) -> void:
	character_index = clampi(index, 0, 9)
	archetype = character_index / 2
	gender = character_index % 2
	var accents: Array[Color] = [Color("62eacb"), Color("ffbd69"), Color("b48cff"), Color("62b5ff"), Color("ff719d")]
	accent = accents[archetype]
	skin = [Color("f2b58f"), Color("c98262"), Color("edc29e"), Color("9d604b"), Color("f0a982")][character_index % 5]
	hair = [Color("26344f"), Color("563d72"), Color("172c38"), Color("773e45"), Color("392a24")][archetype]
	queue_redraw()

func configure_equipment(loadout: Dictionary) -> void:
	equipment = loadout
	queue_redraw()

func advance(delta: float) -> void:
	hurt_time = maxf(0, hurt_time - delta)
	shoot_flash = maxf(0, shoot_flash - delta)
	level_up_time = maxf(0, level_up_time - delta)
	pulse += delta
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction.length_squared() > direction.length_squared():
		direction = touch_direction
	var smoothing := 18.0 if direction.length_squared() > 0.01 else 24.0
	smoothed_direction = smoothed_direction.lerp(direction, clampf(delta * smoothing, 0.0, 1.0))
	if smoothed_direction.length() < 0.025:
		smoothed_direction = Vector2.ZERO
	velocity = smoothed_direction * speed if active else Vector2.ZERO
	if smoothed_direction.length_squared() > 0.01:
		facing = smoothed_direction.normalized()
	move_and_slide()
	position = position.clamp(arena.position + Vector2.ONE * 25, arena.end - Vector2.ONE * 25)
	queue_redraw()

func _draw() -> void:
	var weapon_anchor := Vector2(0, -22)
	var muzzle := weapon_anchor + facing * 34.0
	draw_line(weapon_anchor - facing * 10.0, muzzle, Color("1c3148"), 9)
	draw_line(weapon_anchor - facing * 4.0, muzzle, accent.lightened(0.32), 4)
	if shoot_flash > 0.0:
		draw_circle(muzzle, 12.0 * clampf(shoot_flash / 0.12, 0.0, 1.0), Color("fff2b0", 0.80))
		draw_line(muzzle, muzzle + facing * 20.0, Color("fff2b0", 0.75), 3)
	if level_up_time > 0.0:
		var alpha := clampf(level_up_time / 0.35, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-58, -112 - (1.0 - alpha) * 12.0), "LEVEL UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.82, 0.32, alpha))
		draw_arc(Vector2.ZERO, 52.0 + (1.0 - alpha) * 18.0, 0, TAU, 32, Color(1.0, 0.82, 0.32, alpha * 0.7), 3)
	var marker_y := -88.0 + sin(pulse * 4.0) * 3.0
	draw_circle(Vector2(0, marker_y + 5), 10, Color(0.20, 0.95, 0.84, 0.10))
	draw_colored_polygon(PackedVector2Array([Vector2(0, marker_y - 7), Vector2(8, marker_y), Vector2(0, marker_y + 7), Vector2(-8, marker_y)]), Color("d8fff8"))
	draw_arc(Vector2(0, marker_y), 12, PI * 0.1, PI * 0.9, 12, Color("55ebd2"), 2)
	if has_node("ArtVisual"):
		if hurt_time > 0:
			draw_arc(Vector2.ZERO, 42, 0, TAU, 32, Color("ff647b"), 5)
		return
	var bob: float = sin(pulse * 7.0) * 1.5 if velocity.length_squared() > 0 else 0.0
	var body := Vector2(0, bob)
	# Soft contact shadow and energy ring make the sprite read against the arena.
	draw_shadow_ellipse(body + Vector2(0, 25), Vector2(25, 8), Color(0.01, 0.03, 0.08, 0.55))
	draw_arc(Vector2.ZERO, 34, -pulse * 0.8, TAU - pulse * 0.8, 32, Color(accent, 0.28), 2)
	match archetype:
		0: draw_vanguard(body)
		1: draw_runner(body)
		2: draw_tech(body)
		3: draw_warden(body)
		4: draw_duelist(body)
	if hurt_time > 0:
		draw_arc(Vector2.ZERO, 42, 0, TAU, 32, Color("ff647b"), 5)
		if not reduced_effects:
			draw_circle(Vector2.ZERO, 28, Color(1, 0.3, 0.4, clampf(hurt_time, 0, 0.7)))
	if velocity.length_squared() > 0:
		draw_line(Vector2.ZERO, velocity.normalized() * 42, Color("f4f7ff"), 4)

func register_shot() -> void:
	shoot_flash = 0.12
	queue_redraw()

func show_level_up() -> void:
	level_up_time = 1.6
	queue_redraw()

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func draw_humanoid(body: Vector2, torso: PackedVector2Array, head_radius: float) -> void:
	var leg_offset := 9.0 + sin(pulse * 8.0) * 2.0 if velocity.length_squared() > 0 else 9.0
	draw_line(body + Vector2(-8, 15), body + Vector2(-11, 29 + leg_offset), hair.darkened(0.35), 7)
	draw_line(body + Vector2(8, 15), body + Vector2(11, 29 - leg_offset), hair.darkened(0.35), 7)
	draw_line(body + Vector2(-12, 29 + leg_offset), body + Vector2(-3, 29 + leg_offset), Color("e9f1fa"), 4)
	draw_line(body + Vector2(12, 29 - leg_offset), body + Vector2(21, 29 - leg_offset), Color("e9f1fa"), 4)
	draw_colored_polygon(torso, accent)
	var armor: Dictionary = dict_value(equipment, "GIÁP", {})
	var armor_level: int = int(dict_value(armor, "rarity", 0))
	var armor_color: Color = rarity_colors[clampi(armor_level, 0, rarity_colors.size() - 1)]
	draw_line(body + Vector2(-14, 8), body + Vector2(14, 8), armor_color, 4 + armor_level)
	var boots: Dictionary = dict_value(equipment, "GIÀY", {})
	var boot_color: Color = rarity_colors[clampi(int(dict_value(boots, "rarity", 0)), 0, rarity_colors.size() - 1)]
	draw_line(body + Vector2(-12, 29 + leg_offset), body + Vector2(-3, 29 + leg_offset), boot_color, 4)
	draw_line(body + Vector2(12, 29 - leg_offset), body + Vector2(21, 29 - leg_offset), boot_color, 4)
	draw_polyline(torso + PackedVector2Array([torso[0]]), Color(accent.lightened(0.38)), 3)
	draw_circle(body + Vector2(0, -17), head_radius, skin)
	draw_arc(body + Vector2(0, -18), head_radius + 2, PI, TAU, 20, hair, 7)
	draw_circle(body + Vector2(-5, -18), 2, Color("fff8e7"))
	draw_circle(body + Vector2(5, -18), 2, Color("fff8e7"))
	draw_line(body + Vector2(-4, -10), body + Vector2(4, -10), skin.darkened(0.28), 2)
	draw_line(body + Vector2(-18, 3), body + Vector2(-28, 15), skin, 6)
	draw_line(body + Vector2(18, 3), body + Vector2(28, 15), skin, 6)

func draw_vanguard(body: Vector2) -> void:
	draw_humanoid(body, PackedVector2Array([body + Vector2(-20, -2), body + Vector2(20, -2), body + Vector2(17, 19), body + Vector2(-17, 19)]), 15)
	draw_line(body + Vector2(-12, 4), body + Vector2(12, 4), Color("cafff1"), 3)
	draw_circle(body + Vector2(0, 10), 5, Color("172239"))

func draw_runner(body: Vector2) -> void:
	draw_humanoid(body, PackedVector2Array([body + Vector2(-14, -3), body + Vector2(16, 2), body + Vector2(24, 20), body + Vector2(-22, 18)]), 13)
	draw_line(body + Vector2(-19, 7), body + Vector2(-34, 20), accent.lightened(0.25), 5)
	draw_line(body + Vector2(17, 8), body + Vector2(34, 2), accent.lightened(0.25), 5)

func draw_tech(body: Vector2) -> void:
	draw_humanoid(body, PackedVector2Array([body + Vector2(-20, -5), body + Vector2(20, -5), body + Vector2(18, 21), body + Vector2(-18, 21)]), 13)
	draw_rect(Rect2(body + Vector2(-15, -23), Vector2(30, 9)), hair)
	draw_line(body + Vector2(-10, -18), body + Vector2(10, -18), Color("eafcff"), 3)
	draw_circle(body + Vector2(18, 8), 8, Color("eafcff"))
	draw_circle(body + Vector2(18, 8), 4, accent)

func draw_warden(body: Vector2) -> void:
	draw_circle(body, 28, Color(accent, 0.13))
	draw_humanoid(body, PackedVector2Array([body + Vector2(-22, -4), body + Vector2(22, -4), body + Vector2(16, 20), body + Vector2(-16, 20)]), 14)
	draw_arc(body, 23, 0, TAU, 24, Color("eafcff"), 3)
	draw_circle(body + Vector2(0, 8), 5, Color("eafcff"))

func draw_duelist(body: Vector2) -> void:
	draw_humanoid(body, PackedVector2Array([body + Vector2(-16, -4), body + Vector2(16, -4), body + Vector2(12, 21), body + Vector2(-12, 21)]), 14)
	draw_line(body + Vector2(22, 10), body + Vector2(47, -16), Color("f4f7ff"), 4)
	draw_line(body + Vector2(26, 6), body + Vector2(41, -9), accent.lightened(0.4), 2)
