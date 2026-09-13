extends Node2D

var arena: Rect2
var base: Color
var accent: Color
var map_id: String
var phase: float = 0.0

func configure(value: Rect2, background: Color, map_accent: Color, id: String) -> void:
	arena = value
	base = background
	accent = map_accent
	map_id = id
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	if arena.size == Vector2.ZERO:
		return
	var outer := arena.grow(28)
	var inner := arena.grow(-20)
	var deep := base.darkened(0.50)
	var panel := base.lightened(0.06)
	var line := Color(accent, 0.20)
	var soft_line := Color(accent, 0.10)
	# Outer hull, interior plating and a clear walkable boundary.
	draw_rect(outer, deep)
	draw_rect(arena.grow(12), base.darkened(0.28))
	draw_rect(arena, panel)
	draw_rect(inner, base.darkened(0.08))
	draw_rect(outer, Color(accent, 0.30), false, 3)
	draw_rect(arena, Color(accent, 0.70), false, 5)
	draw_rect(inner, Color(accent, 0.13), false, 2)
	# Deck panels: large quiet areas make enemies, shots and echoes readable.
	for x in range(int(inner.position.x) + 40, int(inner.end.x), 98):
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), soft_line, 1)
	for y in range(int(inner.position.y) + 44, int(inner.end.y), 104):
		draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), soft_line, 1)
	# Broken circuit lanes avoid the perfectly even debug-grid look.
	for lane in range(4):
		var y := inner.position.y + 176.0 + lane * 274.0
		var left := inner.position.x + 48.0 + (lane % 2) * 56.0
		var right := inner.end.x - 48.0 - ((lane + 1) % 2) * 56.0
		draw_line(Vector2(left, y), Vector2(right, y), Color(accent, 0.16), 2)
		for x in range(int(left), int(right), 142):
			draw_rect(Rect2(x, y - 4, 42, 8), Color(accent, 0.22))
			draw_circle(Vector2(x + 52, y), 5, Color(accent, 0.38))
	# The replay core makes the arena identifiable at a glance.
	var core := arena.get_center()
	draw_circle(core, 156, Color(base.darkened(0.45), 0.72))
	draw_circle(core, 128, Color(accent, 0.045))
	for ring in range(3):
		var radius := 74.0 + ring * 28.0
		draw_arc(core, radius, -phase * (0.32 + ring * 0.08), TAU - phase * (0.32 + ring * 0.08), 64, Color(accent, 0.17 + ring * 0.06), 2)
	for spoke in range(8):
		var angle := TAU * spoke / 8.0 + phase * 0.12
		var a := core + Vector2.from_angle(angle) * 114.0
		var b := core + Vector2.from_angle(angle) * 142.0
		draw_line(a, b, Color(accent, 0.30), 3)
	draw_circle(core, 47 + sin(phase * 2.0) * 3.0, Color(accent, 0.08))
	draw_arc(core, 47, 0, TAU, 32, Color(accent, 0.56), 3)
	draw_circle(core, 12, Color(accent, 0.82))
	# Environmental pylons are intentionally outside the active lane, so they do not block movement.
	var pylons := [
		Vector2(arena.position.x + 54, arena.position.y + 80), Vector2(arena.end.x - 54, arena.position.y + 80),
		Vector2(arena.position.x + 54, arena.end.y - 80), Vector2(arena.end.x - 54, arena.end.y - 80),
		Vector2(arena.position.x + 54, core.y), Vector2(arena.end.x - 54, core.y)
	]
	for index in range(pylons.size()):
		draw_pylon(pylons[index], index)
	# Corner brackets and small status lights finish the boundary without visual noise.
	for corner in [arena.position, Vector2(arena.end.x, arena.position.y), Vector2(arena.position.x, arena.end.y), arena.end]:
		draw_arc(corner, 42, 0, TAU, 24, Color(accent, 0.45), 4)
	for y in range(int(arena.position.y) + 100, int(arena.end.y) - 60, 160):
		draw_circle(Vector2(arena.position.x + 18, y), 4, Color(accent, 0.58 + sin(phase * 2.0 + y) * 0.18))
		draw_circle(Vector2(arena.end.x - 18, y), 4, Color(accent, 0.58 + sin(phase * 2.0 + y + 1.0) * 0.18))

func draw_pylon(at: Vector2, index: int) -> void:
	var glow := 0.38 + sin(phase * 2.4 + index) * 0.14
	draw_circle(at + Vector2(4, 7), 28, Color("020712", 0.48))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-19, 19), at + Vector2(19, 19), at + Vector2(12, -17), at + Vector2(-12, -17)]), base.darkened(0.45))
	draw_polyline(PackedVector2Array([at + Vector2(-19, 19), at + Vector2(19, 19), at + Vector2(12, -17), at + Vector2(-12, -17), at + Vector2(-19, 19)]), Color(accent, 0.46), 2)
	draw_circle(at + Vector2(0, -3), 9, Color(accent, glow))
	draw_circle(at + Vector2(0, -3), 3, Color("eaffff"))
