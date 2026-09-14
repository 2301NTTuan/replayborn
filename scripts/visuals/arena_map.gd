extends Node2D

var arena: Rect2
var base: Color
var accent: Color
var map_id: String
var phase: float = 0.0
var redraw_left: float = 0.0
var islands: Array[Dictionary] = []
var veins: Array[Dictionary] = []
var sparks: Array[Vector2] = []

func configure(value: Rect2, background: Color, map_accent: Color, id: String) -> void:
	arena = value
	base = background
	accent = map_accent
	map_id = id
	islands.clear()
	veins.clear()
	sparks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(map_id)) + 51209
	for index in range(11):
		islands.append({
			"center": Vector2(rng.randf_range(arena.position.x + 150.0, arena.end.x - 150.0), rng.randf_range(arena.position.y + 180.0, arena.end.y - 180.0)),
			"radius": rng.randf_range(90.0, 230.0),
			"stretch": rng.randf_range(0.48, 0.86),
			"angle": rng.randf_range(0.0, TAU),
			"tone": rng.randf_range(0.02, 0.12)
		})
	for index in range(18):
		var start := Vector2(rng.randf_range(arena.position.x + 120.0, arena.end.x - 120.0), rng.randf_range(arena.position.y + 150.0, arena.end.y - 150.0))
		veins.append({
			"start": start,
			"mid": start + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(80.0, 220.0),
			"end": start + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(130.0, 360.0),
			"alpha": rng.randf_range(0.05, 0.16)
		})
	for index in range(34):
		sparks.append(Vector2(rng.randf_range(arena.position.x + 80.0, arena.end.x - 80.0), rng.randf_range(arena.position.y + 100.0, arena.end.y - 100.0)))
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	redraw_left -= delta
	if redraw_left <= 0.0:
		redraw_left = 0.12
		queue_redraw()

func _draw() -> void:
	if arena.size == Vector2.ZERO:
		return
	# The camera deliberately exposes a large strip above the playable boundary
	# so the HUD never overlaps a playable actor. Paint that strip as map too;
	# otherwise the engine clear colour shows through at the top of a run.
	var outer := arena.grow_individual(70.0, 460.0, 70.0, 70.0)
	# The camera can look into the protected strip above the arena. It is part of
	# the environment, not a black void between HUD and gameplay.
	draw_rect(outer, base.darkened(0.30))
	for band_index in range(6):
		var band_y: float = arena.position.y - 410.0 + band_index * 78.0
		var wobble: float = sin(phase * 0.45 + band_index * 1.7) * 12.0
		draw_line(Vector2(outer.position.x + 30.0, band_y + wobble), Vector2(outer.end.x - 30.0, band_y - wobble), Color(accent, 0.055), 1.5)
		for dot_index in range(4):
			var dot_x: float = outer.position.x + 120.0 + dot_index * (outer.size.x - 240.0) / 3.0 + sin(phase + band_index * 2.0 + dot_index) * 18.0
			draw_circle(Vector2(dot_x, band_y + wobble * 0.4), 2.0, Color(accent, 0.16))
	draw_rect(arena, base.darkened(0.36))
	draw_circle(arena.get_center(), maxf(arena.size.x, arena.size.y) * 0.42, Color(base.lightened(0.03), 0.28))
	draw_circle(arena.get_center() + Vector2(120, -240), maxf(arena.size.x, arena.size.y) * 0.26, Color(accent, 0.035))
	for island in islands:
		draw_island(island)
	for vein in veins:
		draw_vein(vein)
	for index in range(sparks.size()):
		var at := sparks[index] + Vector2(0, sin(phase * 0.9 + index) * 5.0)
		var glow := 0.22 + sin(phase * 1.4 + index * 0.63) * 0.10
		draw_circle(at, 12.0, Color(accent, glow * 0.05))
		draw_circle(at, 2.3, Color(accent, glow))
	draw_boundary()

func draw_island(data: Dictionary) -> void:
	var center: Vector2 = data.center
	var radius: float = float(data.radius)
	var stretch: float = float(data.stretch)
	var angle: float = float(data.angle)
	var tone: float = float(data.tone)
	var points := PackedVector2Array()
	for step in range(18):
		var theta := TAU * step / 18.0
		var wobble := 0.84 + sin(theta * 3.0 + angle) * 0.10 + cos(theta * 5.0 - angle) * 0.06
		var local := Vector2(cos(theta) * radius * wobble, sin(theta) * radius * stretch * wobble).rotated(angle)
		points.append(center + local)
	draw_colored_polygon(points, Color(base.darkened(0.26 + tone), 0.72))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(accent, 0.045 + tone * 0.28), 2.0)

func draw_vein(data: Dictionary) -> void:
	var start: Vector2 = data.start
	var mid: Vector2 = data.mid
	var finish: Vector2 = data.end
	var alpha: float = float(data.alpha)
	var last := start
	for segment in range(1, 15):
		var t := float(segment) / 14.0
		var a := start.lerp(mid, t)
		var b := mid.lerp(finish, t)
		var point := a.lerp(b, t)
		draw_line(last, point, Color("01040a", 0.24), 5.0)
		draw_line(last, point, Color(accent, alpha), 1.7)
		last = point

func draw_boundary() -> void:
	var edge := Color(accent, 0.34)
	draw_rect(arena, Color("e8fbff", 0.045), false, 2.0)
	draw_line(arena.position + Vector2(34, 24), arena.position + Vector2(170, 24), edge, 4.0)
	draw_line(Vector2(arena.end.x - 170, arena.position.y + 24), Vector2(arena.end.x - 34, arena.position.y + 24), edge, 4.0)
	draw_line(Vector2(arena.position.x + 34, arena.end.y - 24), Vector2(arena.position.x + 170, arena.end.y - 24), edge, 4.0)
	draw_line(arena.end - Vector2(170, 24), arena.end - Vector2(34, 24), edge, 4.0)
	var corners: Array[Vector2] = [arena.position, Vector2(arena.end.x, arena.position.y), Vector2(arena.position.x, arena.end.y), arena.end]
	for index in range(4):
		var corner: Vector2 = corners[index]
		draw_circle(corner, 22.0, Color(accent, 0.08))
