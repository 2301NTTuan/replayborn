extends Control
## Brief skippable brand reveal. Loading is asynchronous; no invented percentages.
const Art = preload("res://ui/title_art.gd")
const MENU_PATH := "res://scenes/menu.tscn"
var elapsed: float = 0.0
var leaving: bool = false
var skip_requested: bool = false
var reduced: bool = false
var logo: TextureRect
var hint: Label
var loaded_menu: PackedScene
var load_failed: bool = false

func _ready() -> void:
	var profile := get_node("/root/Profile")
	reduced = bool(profile.data.reduced)
	RenderingServer.set_default_clear_color(Color("050b14"))
	var art := Art.new()
	art.cinematic = true
	art.reduced = reduced
	add_child(art)
	logo = Art.picture(Art.EMBLEM)
	logo.name = "BrandEmblem"
	Art.place(logo, self, Rect2(0.045, 0.25, 0.91, 0.36))
	logo.modulate.a = 0.0
	var reveal := create_tween()
	reveal.tween_property(logo, "modulate:a", 1.0, 0.15 if reduced else 0.65)
	var vi: bool = profile.data.language == "vi"
	var line := Art.caption("ĐƯỜNG ĐI TRỞ THÀNH VŨ KHÍ" if vi else "YOUR PATH BECOMES YOUR WEAPON", 22, Color("a3c3d2"))
	Art.place(line, self, Rect2(0.08, 0.635, 0.84, 0.04))
	hint = Art.caption("Đang tải…" if vi else "Loading…", 20, Color("7e9cab"))
	Art.place(hint, self, Rect2(0.1, 0.90, 0.8, 0.04))
	var error := ResourceLoader.load_threaded_request(MENU_PATH)
	if error != OK:
		load_failed = true
		hint.text = "Không thể tải menu. Hãy mở lại game." if vi else "Menu could not load. Please restart."
		push_error("Menu load request failed: %s" % error)

func _process(delta: float) -> void:
	elapsed += delta
	if leaving or load_failed:
		return
	if loaded_menu == null:
		var status := ResourceLoader.load_threaded_get_status(MENU_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loaded_menu = ResourceLoader.load_threaded_get(MENU_PATH) as PackedScene
			hint.text = "CHẠM ĐỂ TIẾP TỤC" if get_node("/root/Profile").data.language == "vi" else "TAP TO CONTINUE"
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			load_failed = true
			hint.text = "Không thể tải menu / Menu could not load"
	if loaded_menu != null and (skip_requested or elapsed >= (0.5 if reduced else 2.1)):
		continue_to_menu()

func _input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed()
	if tap and elapsed >= 0.15:
		skip_requested = true
		get_viewport().set_input_as_handled()

func continue_to_menu() -> void:
	if leaving or loaded_menu == null:
		return
	leaving = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.08 if reduced else 0.25)
	fade.tween_callback(_open_menu)

func _open_menu() -> void:
	var error := get_tree().change_scene_to_packed(loaded_menu)
	if error != OK:
		leaving = false
		load_failed = true
		modulate.a = 1.0
		hint.text = "Không thể mở menu / Menu could not open"
