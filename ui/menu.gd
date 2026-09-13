extends Control
const UI = preload("res://ui/ui_kit.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var profile: Node
var body: VBoxContainer

func _ready() -> void:
	profile = get_node("/root/Profile")
	theme = UI.theme()
	body = UI.column(self, Rect2(100, 460, 880, 1320))
	show_home()
	RenderingServer.set_default_clear_color(Color("090f1d"))

func t(key: String) -> String:
	return UI.text(key, profile)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), Color("090f1d"))
	for index in range(4):
		draw_arc(Vector2(540, 240), 70 + index * 30, -PI * 0.85, PI * 0.7, 64, Color(0.38, 0.92, 0.8, 0.75 - index * 0.16), 4)
	draw_circle(Vector2(540, 240), 32, Color("62eacb"))
	draw_string(ThemeDB.fallback_font, Vector2(245, 425), "REPLAYBORN", HORIZONTAL_ALIGNMENT_LEFT, -1, 78, Color("e0fff7"))

func show_home() -> void:
	UI.clear(body)
	UI.label(body, t("tagline"), 26, true)
	UI.label(body, t("records") % [profile.data.runs, profile.data.wins, profile.data.kills], 25, true)
	if not profile.warning.is_empty():
		UI.label(body, t(profile.warning), 24, true)
	UI.label(body, t("weapon"), 26)
	UI.label(body, t("character"), 26)
	var character_picker := OptionButton.new()
	character_picker.custom_minimum_size.y = 90
	var character_names: Array = ["Vanguard · Nam / Male", "Vanguard · Nữ / Female", "Runner · Nam / Male", "Runner · Nữ / Female", "Tech · Nam / Male", "Tech · Nữ / Female", "Warden · Nam / Male", "Warden · Nữ / Female", "Duelist · Nam / Male", "Duelist · Nữ / Female"]
	for name in character_names:
		character_picker.add_item(name)
	character_picker.select(profile.data.character)
	body.add_child(character_picker)
	character_picker.item_selected.connect(func(index: int) -> void: profile.setting("character", index))
	UI.label(body, t("map"), 26)
	var map_picker := OptionButton.new()
	map_picker.custom_minimum_size.y = 90
	for map_data in Catalog.MAPS:
		var map_name: String = map_data.title_en if profile.data.language == "en" else map_data.title_vi
		map_picker.add_item(map_name + " · " + (map_data.subtitle_en if profile.data.language == "en" else map_data.subtitle_vi))
	map_picker.select(profile.data.map)
	body.add_child(map_picker)
	map_picker.item_selected.connect(func(index: int) -> void: profile.setting("map", index))
	var weapon_picker := OptionButton.new()
	weapon_picker.custom_minimum_size.y = 90
	for weapon in Catalog.WEAPONS:
		weapon_picker.add_item(t(weapon.id))
	weapon_picker.select(profile.selected_weapon)
	body.add_child(weapon_picker)
	var description := UI.label(body, t(Catalog.WEAPONS[profile.selected_weapon].id + "_desc"), 25)
	weapon_picker.item_selected.connect(func(index: int) -> void:
		profile.selected_weapon = index
		profile.setting("weapon", index)
		description.text = t(Catalog.WEAPONS[index].id + "_desc"))
	UI.button(body, t("start"), func() -> void: launch(false), 105).grab_focus()
	UI.button(body, t("practice"), func() -> void: launch(true))
	UI.button(body, t("settings"), show_settings)
	UI.button(body, t("help"), show_help)
	UI.button(body, t("quit"), func() -> void: get_tree().quit())
	UI.label(body, "1.0.0-rc.1  ·  OFFLINE", 23, true)

func launch(practice: bool) -> void:
	profile.practice = practice
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func show_settings() -> void:
	UI.clear(body)
	UI.label(body, t("settings"), 44)
	UI.settings(body, profile, show_settings)
	UI.button(body, t("back"), show_home)

func show_help() -> void:
	UI.clear(body)
	UI.label(body, t("help"), 44)
	UI.label(body, t("help_body"), 29)
	UI.button(body, t("back"), show_home)
