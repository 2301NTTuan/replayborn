extends Control

const DISPLAY_FONT = preload("res://assets/fonts/CascadiaCode.ttf")
var elapsed: float = 0.0
var leaving: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("050812"))
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= 1.2:
		continue_to_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and elapsed >= 0.15:
		continue_to_menu()

func continue_to_menu() -> void:
	if leaving:
		return
	leaving = true
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050812"))
	var pulse: float = 0.72 + sin(elapsed * 5.0) * 0.12
	draw_circle(Vector2(540, 820), 148, Color(0.15, 0.9, 0.82, 0.08 * pulse))
	draw_arc(Vector2(540, 820), 104, -PI * 0.2, PI * 1.55, 64, Color(0.35, 1.0, 0.92, pulse), 7)
	draw_line(Vector2(470, 875), Vector2(620, 765), Color("ffd166", pulse), 5)
	draw_string(DISPLAY_FONT, Vector2(0, 1060), "REPLAYBORN", HORIZONTAL_ALIGNMENT_CENTER, 1080, 72, Color("edf6ff", pulse))
	draw_string(DISPLAY_FONT, Vector2(0, 1110), "YOUR PATH BECOMES YOUR WEAPON", HORIZONTAL_ALIGNMENT_CENTER, 1080, 20, Color("72f6d4", pulse))
