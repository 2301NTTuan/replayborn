extends Control

var character_index: int = 0
var selected: bool = false
var accent: Color = Color("62eacb")

func setup(index: int, active: bool) -> void:
	character_index = index
	selected = active
	accent = [Color("62eacb"), Color("ffbd69"), Color("b48cff"), Color("62b5ff"), Color("ff719d")][index / 2]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 800, 190), Color("13243a") if not selected else Color("19475a"))
	draw_rect(Rect2(0, 0, 800, 190), accent if selected else Color("2d4963"), false, 3)
	var center := Vector2(105, 96)
	draw_circle(center + Vector2(0, 46), 35, Color(0.01, 0.03, 0.08, 0.5))
	draw_circle(center + Vector2(0, -15), 29, Color("e7ad87"))
	draw_circle(center + Vector2(0, 12), 39, accent)
	draw_arc(center + Vector2(0, -20), 31, PI, TAU, 24, Color("28334f"), 11)
	draw_circle(center + Vector2(-10, -20), 3, Color("fff8e7"))
	draw_circle(center + Vector2(10, -20), 3, Color("fff8e7"))
	match character_index / 2:
		0: draw_rect(Rect2(center + Vector2(-28, 0), Vector2(56, 45)), accent)
		1: draw_colored_polygon(PackedVector2Array([center + Vector2(-42, 45), center + Vector2(0, -4), center + Vector2(42, 45)]), accent)
		2: draw_rect(Rect2(center + Vector2(-35, -45), Vector2(70, 14)), Color("28334f"))
		3: draw_arc(center, 55, 0, TAU, 24, Color(accent, 0.4), 8)
		4: draw_line(center + Vector2(40, 28), center + Vector2(95, -20), Color("f4f7ff"), 6)
	var gender := "NỮ / FEMALE" if character_index % 2 else "NAM / MALE"
	draw_string(ThemeDB.fallback_font, Vector2(205, 78), ["VANGUARD", "RUNNER", "TECH", "WARDEN", "DUELIST"][character_index / 2], HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("edf6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(205, 122), gender, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, accent)
	draw_string(ThemeDB.fallback_font, Vector2(205, 157), "ĐANG CHỌN / SELECTED" if selected else "Chạm để chọn / Tap to select", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("a9bfd4"))
