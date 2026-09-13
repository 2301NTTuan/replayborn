extends Control
const UI = preload("res://ui/ui_kit.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const CharacterThumb = preload("res://ui/character_thumb.gd")
const MapThumb = preload("res://ui/map_thumb.gd")
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
	UI.button(body, t("character_menu"), show_character_select)
	UI.button(body, t("map_menu"), show_map_select)
	UI.button(body, t("loadout"), show_loadout)
	UI.button(body, t("shop"), show_shop)
	UI.button(body, t("missions"), show_missions)
	var selected := UI.label(body, "%s: %d  ·  %s: %d" % [t("selected_character"), profile.data.character + 1, t("selected_map"), profile.data.map + 1], 24, true)
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

func show_loadout() -> void:
	UI.clear(body)
	UI.label(body, t("loadout"), 44, true)
	UI.label(body, "Áo · Quần · Giày · Giáp · Vũ khí", 24, true)
	UI.label(body, "Mảnh: %s  ·  Lõi nâng cấp: %d  ·  Vàng: %d" % [str(profile.data.shards), profile.data.upgrade_core, profile.data.gold], 22, true)
	for slot in profile.SLOTS:
		var item: Dictionary = profile.data.equipment[slot]
		var rarity: String = profile.RARITIES[int(item.rarity)]
		UI.button(body, "%s  ·  %s  ·  Lv.%d" % [slot, rarity, item.level], func() -> void:
			if profile.upgrade_equipment(slot):
				show_loadout())
		UI.label(body, "Nâng cấp: %d mảnh + %d lõi" % [10 + int(item.level) * 8, 5 + int(item.level) * 4], 19)
	UI.button(body, t("back"), show_home).grab_focus()

func show_shop() -> void:
	UI.clear(body)
	UI.label(body, t("shop"), 44, true)
	UI.label(body, "Vàng: %d  ·  Payment thật chưa kết nối" % profile.data.gold, 24, true)
	UI.label(body, "Rương có lượt mở miễn phí theo chu kỳ ngày; mở trả phí dùng vàng.", 21, true)
	for rarity_index in range(profile.RARITIES.size()):
		var rarity: String = profile.RARITIES[rarity_index]
		var chest: Dictionary = profile.data.chests[rarity]
		var ready: String = "FREE READY" if profile.chest_ready(rarity) else "FREE COOLDOWN %d ngày" % chest.free_days
		UI.label(body, "%s  ·  %s  ·  %d vàng" % [rarity, ready, chest.gold], 25)
		for slot in profile.SLOTS:
			UI.button(body, "%s · Mở miễn phí" % slot, func() -> void:
				profile.open_chest(slot, rarity_index, false)
				show_shop(), 62)
			UI.button(body, "%s · Mở bằng vàng" % slot, func() -> void:
				profile.open_chest(slot, rarity_index, true)
				show_shop(), 62)
	UI.button(body, t("back"), show_home).grab_focus()

func show_missions() -> void:
	UI.clear(body)
	UI.label(body, t("missions"), 44, true)
	var missions: Dictionary = profile.data.missions
	UI.label(body, "Hạ 100 quái: %d / 100" % mini(100, int(missions.kills)), 26)
	if not missions.claimed_kills and missions.kills >= 100:
		UI.button(body, "Nhận thưởng · 500 vàng + 50 lõi", func() -> void:
			profile.add_rewards(500, 50)
			profile.data.missions.claimed_kills = true
			profile.save_profile()
			show_missions())
	else:
		UI.label(body, "Thưởng: 500 vàng + 50 lõi" if not missions.claimed_kills else "Đã nhận", 22)
	UI.label(body, "Thắng 1 trận: %d / 1" % mini(1, int(missions.wins)), 26)
	if not missions.claimed_wins and missions.wins >= 1:
		UI.button(body, "Nhận thưởng · 1000 vàng + 100 lõi", func() -> void:
			profile.add_rewards(1000, 100)
			profile.data.missions.claimed_wins = true
			profile.save_profile()
			show_missions())
	else:
		UI.label(body, "Thưởng: 1000 vàng + 100 lõi" if not missions.claimed_wins else "Đã nhận", 22)
	UI.button(body, t("back"), show_home).grab_focus()

func show_character_select() -> void:
	UI.clear(body)
	UI.label(body, t("character_menu"), 44, true)
	UI.label(body, "5 archetype × Nam/Nữ · chỉ số giống nhau, silhouette khác nhau", 23, true)
	for index in range(10):
		var thumb := CharacterThumb.new()
		thumb.custom_minimum_size = Vector2(0, 190)
		thumb.setup(index, index == profile.data.character)
		body.add_child(thumb)
		thumb.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				profile.setting("character", index)
				show_character_select())
	UI.button(body, t("back"), show_home).grab_focus()

func show_map_select() -> void:
	UI.clear(body)
	UI.label(body, t("map_menu"), 44, true)
	UI.label(body, "10 map · mỗi map 10 level · mỗi level 1 boss", 23, true)
	for index in range(Catalog.MAPS.size()):
		var thumb := MapThumb.new()
		thumb.custom_minimum_size = Vector2(0, 190)
		thumb.setup(Catalog.MAPS[index], index == profile.data.map)
		body.add_child(thumb)
		thumb.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				profile.setting("map", index)
				show_map_select())
	UI.button(body, t("back"), show_home).grab_focus()

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
