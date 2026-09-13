extends Control

var map_data: Resource
var selected: bool = false

func setup(data: Resource, active: bool) -> void:
    map_data = data
    selected = active
    queue_redraw()

func _draw() -> void:
    var width := size.x if size.x > 10 else 800.0
    var frame: Color = map_data.accent if selected else Color("2d4963")
    var tex: Texture2D = load("res://assets/replayborn/maps/%s/thumbnail.png" % String(map_data.id))
    draw_texture_rect(tex, Rect2(0, 0, width, 190), true)
    draw_rect(Rect2(0, 0, width, 190), Color(0.02, 0.04, 0.08, 0.42))
    draw_rect(Rect2(0, 0, width, 190), frame, false, 3)
    draw_rect(Rect2(0, 0, 9, 190), map_data.accent)
    draw_string(ThemeDB.fallback_font, Vector2(30, 45), map_data.title_vi + " / " + map_data.title_en, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("edf6ff"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 82), map_data.subtitle_vi, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, map_data.accent)
    draw_string(ThemeDB.fallback_font, Vector2(30, 160), "5 LEVELS  ·  5 BOSSES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d0ddec"))
    if selected:
        draw_string(ThemeDB.fallback_font, Vector2(width - 210, 160), "ĐANG CHỌN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, map_data.accent)
