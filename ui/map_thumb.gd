extends Control

var map_data: Resource
var selected: bool = false

func setup(data: Resource, active: bool) -> void:
	map_data = data
	selected = active
	queue_redraw()

func _draw() -> void:
	var frame: Color = map_data.accent if selected else Color("2d4963")
	draw_rect(Rect2(0, 0, 800, 190), map_data.background)
	draw_rect(Rect2(0, 0, 800, 190), frame, false, 3)
	for x in range(20, 800, 55):
		draw_line(Vector2(x, 0), Vector2(x - 70, 190), Color(map_data.accent, 0.10), 2)
	for y in range(28, 190, 42):
		draw_line(Vector2(0, y), Vector2(800, y), Color(map_data.accent, 0.11), 2)
	for index in range(4):
		var p := Vector2(120 + index * 180, 75 + (index % 2) * 40)
		draw_circle(p, 16 + index * 2, Color(map_data.accent, 0.18))
		draw_arc(p, 22 + index * 2, 0, TAU, 16, map_data.accent, 3)
	draw_string(ThemeDB.fallback_font, Vector2(30, 45), map_data.title_vi + " / " + map_data.title_en, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("edf6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(30, 82), map_data.subtitle_vi, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, map_data.accent)
	draw_string(ThemeDB.fallback_font, Vector2(30, 160), "10 LEVELS  ·  10 BOSSES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d0ddec"))
	if selected:
		draw_string(ThemeDB.fallback_font, Vector2(585, 160), "ĐANG CHỌN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, map_data.accent)
