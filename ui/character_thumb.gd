extends Control

var character_index: int = 0
var selected: bool = false
var accent: Color = Color("62eacb")
const IDS := ["vanguard_m","vanguard_f","runner_m","runner_f","tech_m","tech_f","warden_m","warden_f","duelist_m","duelist_f"]

func setup(index: int, active: bool) -> void:
    character_index = index
    selected = active
    accent = [Color("62eacb"), Color("ffbd69"), Color("b48cff"), Color("62b5ff"), Color("ff719d")][index / 2]
    queue_redraw()

func _draw() -> void:
    var width := size.x if size.x > 10 else 800.0
    draw_rect(Rect2(0, 0, width, 190), Color("13243a") if not selected else Color("19475a"))
    draw_rect(Rect2(0, 0, width, 190), accent if selected else Color("2d4963"), false, 3)
    draw_rect(Rect2(0, 0, 9, 190), accent)
    var tex: Texture2D = load("res://assets/replayborn/characters/%s/portrait.png" % IDS[character_index])
    draw_texture_rect(tex, Rect2(24, 8, 176, 176), false)
    var gender := "NỮ / FEMALE" if character_index % 2 else "NAM / MALE"
    draw_string(ThemeDB.fallback_font, Vector2(215, 72), ["VANGUARD", "RUNNER", "TECH", "WARDEN", "DUELIST"][character_index / 2], HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("edf6ff"))
    draw_string(ThemeDB.fallback_font, Vector2(215, 116), gender, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, accent)
    draw_string(ThemeDB.fallback_font, Vector2(215, 154), "ĐANG CHỌN / SELECTED" if selected else "Chạm để chọn / Tap to select", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, accent if selected else Color("a9bfd4"))
