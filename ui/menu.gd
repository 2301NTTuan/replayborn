extends Control
const UI = preload("res://ui/ui_kit.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const CharacterThumb = preload("res://ui/character_thumb.gd")
const MapThumb = preload("res://ui/map_thumb.gd")
var profile: Node
var body: VBoxContainer
var back_button: Button

func _ready() -> void:
	profile = get_node("/root/Profile")
	theme = UI.theme()
	body = UI.column(self, Rect2(100, 460, 880, 1320))
	back_button = UI.button(self, "←  " + t("back"), show_home, 82)
	back_button.position = Vector2(42, 42)
	back_button.size = Vector2(260, 82)
	back_button.hide()
	show_home()
	RenderingServer.set_default_clear_color(Color("090f1d"))

func t(key: String) -> String:
	return UI.text(key, profile)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), Color("090f1d"))
	draw_circle(Vector2(540, 250), 390, Color(0.08, 0.20, 0.28, 0.16))
	draw_circle(Vector2(540, 250), 250, Color(0.10, 0.34, 0.38, 0.13))
	draw_rect(Rect2(42, 395, 996, 1410), Color("0e1b2d"))
	draw_rect(Rect2(42, 395, 996, 1410), Color("31506d"), false, 3)
	draw_line(Vector2(75, 445), Vector2(1005, 445), Color("62eacb"), 3)
	for index in range(4):
		draw_arc(Vector2(540, 240), 70 + index * 30, -PI * 0.85, PI * 0.7, 64, Color(0.38, 0.92, 0.8, 0.75 - index * 0.16), 4)
	draw_circle(Vector2(540, 240), 32, Color("62eacb"))
	draw_string(ThemeDB.fallback_font, Vector2(245, 425), "REPLAYBORN", HORIZONTAL_ALIGNMENT_LEFT, -1, 78, Color("e0fff7"))

func show_home() -> void:
	UI.clear(body)
	back_button.hide()
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
	show_back_button()

func show_shop() -> void:
	UI.clear(body)
	UI.label(body, t("shop"), 44, true)
	UI.label(body, "Vàng: %d  ·  Key free được ưu tiên trước" % profile.data.gold, 24, true)
	UI.label(body, "Chọn từng loại rương và độ hiếm. Nếu hết lượt free, hệ thống tự dùng vàng mua key.", 21, true)
	for slot in profile.SLOTS:
		UI.label(body, "━━  RƯƠNG %s  ━━" % slot, 31, true)
		for rarity_index in range(profile.RARITIES.size()):
			var rarity: String = profile.RARITIES[rarity_index]
			var chest: Dictionary = profile.data.chests[rarity]
			var ready: String = "KEY FREE SẴN" if profile.chest_ready(rarity) else "KEY FREE sau %d ngày" % chest.free_days
			UI.button(body, "%s  ·  %s  ·  %d vàng/key" % [rarity, ready, chest.gold], func() -> void:
				open_shop_chest(slot, rarity_index), 70)
	show_back_button()

func open_shop_chest(slot: String, rarity_index: int) -> void:
	var result: Dictionary = profile.open_chest_with_priority(slot, rarity_index)
	match result.get("status", ""):
		"free":
			show_shop()
		"gold":
			show_shop()
		"payment":
			show_payment_popup(slot, rarity_index, int(result.get("cost", 0)))
		_:
			show_shop()

func show_payment_popup(slot: String, rarity_index: int, cost: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Mua key mở rương"
	dialog.dialog_text = "Bạn không đủ vàng để mua key %s %s (cần %d vàng).\nPayment thật sẽ được tích hợp ở bước phát hành." % [slot, profile.RARITIES[rarity_index], cost]
	dialog.ok_button_text = "Mua key qua payment"
	dialog.cancel_button_text = "Để sau"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		dialog.queue_free()
		show_shop())
	dialog.canceled.connect(func() -> void:
		dialog.queue_free())
	dialog.popup_centered(Vector2(760, 300))

func show_missions() -> void:
	UI.clear(body)
	show_back_button()
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

func show_character_select() -> void:
	UI.clear(body)
	show_back_button()
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

func show_map_select() -> void:
	UI.clear(body)
	show_back_button()
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

func launch(practice: bool) -> void:
	profile.practice = practice
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func show_settings() -> void:
	UI.clear(body)
	show_back_button()
	UI.label(body, t("settings"), 44)
	UI.settings(body, profile, show_settings)

func show_help() -> void:
	UI.clear(body)
	show_back_button()
	UI.label(body, t("help"), 44)
	UI.label(body, t("help_body"), 29)

func show_back_button() -> void:
	back_button.text = "←  " + t("back")
	back_button.show()
	back_button.grab_focus()
