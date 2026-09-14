extends Control
const UI = preload("res://ui/ui_kit.gd")
const DISPLAY_FONT = preload("res://assets/fonts/CascadiaCode.ttf")
const Catalog = preload("res://scripts/data/catalog.gd")
const CharacterThumb = preload("res://ui/character_thumb.gd")
const MapThumb = preload("res://ui/map_thumb.gd")
const HEROINE_SHEET = preload("res://assets/original_v1/astria_run_v1.png")
var profile: Node
var body: VBoxContainer
var back_button: Button
var subpage_active: bool = false

func dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func _ready() -> void:
	profile = get_node("/root/Profile")
	theme = UI.theme()
	body = UI.column(self, Rect2(64, 760, 952, 1072))
	back_button = UI.button(self, "←  " + t("back"), show_home, 82)
	back_button.position = Vector2(54, 46)
	back_button.size = Vector2(196, 62)
	back_button.hide()
	show_home()
	RenderingServer.set_default_clear_color(Color("090f1d"))

func t(key: String) -> String:
	return UI.text(key, profile)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), Color("050812"))
	draw_rect(Rect2(0, 0, 1080, 1920), Color("071827", 0.54))
	for index in range(9):
		var y := 170.0 + index * 165.0
		draw_line(Vector2(0, y), Vector2(1080, y - 88.0), Color("16304a", 0.18), 2)
	draw_circle(Vector2(820, 335), 430, Color("15334a", 0.46))
	draw_circle(Vector2(822, 340), 260, Color("1a685f", 0.16))
	draw_texture_rect_region(HEROINE_SHEET, Rect2(600, 164, 372, 494), Rect2(0, 0, HEROINE_SHEET.get_width() / 4, HEROINE_SHEET.get_height()), Color.WHITE)
	draw_line(Vector2(64, 688), Vector2(1016, 688), Color("72f6d4", 0.64), 3)
	draw_rect(Rect2(42, 720, 996, 1140), Color("070d18", 0.88))
	draw_rect(Rect2(42, 720, 996, 1140), Color("24384f", 0.9), false, 1)
	draw_string(DISPLAY_FONT, Vector2(64, 156), "REPLAYBORN", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color("edf6ff"))
	draw_string(DISPLAY_FONT, Vector2(68, 205), "ECHO SURVIVAL  /  MOBILE BUILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("72f6d4"))
	draw_string(DISPLAY_FONT, Vector2(68, 330), "VOID GARDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("edf6ff"))
	draw_string(DISPLAY_FONT, Vector2(70, 374), "5 LEVELS  •  5 BOSSES  •  OFFLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8fa7ba"))
	draw_rect(Rect2(64, 470, 438, 112), Color("0c1624", 0.82))
	draw_rect(Rect2(64, 470, 438, 112), Color("263c55"), false, 1)
	draw_line(Vector2(86, 498), Vector2(194, 498), Color("f2c45b"), 3)
	draw_string(DISPLAY_FONT, Vector2(86, 535), "ASTRIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("edf6ff"))
	draw_string(DISPLAY_FONT, Vector2(86, 565), "ECHO RUNNER  ·  READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("9cb2c6"))
	if subpage_active:
		draw_rect(Rect2(0, 0, 1080, 1920), Color(0.012, 0.018, 0.032, 0.92))

func show_home() -> void:
	UI.clear(body)
	subpage_active = false
	queue_redraw()
	back_button.hide()
	UI.caption(body, "RUN DOCK", true)
	var status := UI.card(body, Color("2a4058"))
	UI.label(status, "HỒ SƠ", 18, true)
	var record_label := UI.label(status, t("records") % [profile.data.runs, profile.data.wins, profile.data.kills], 22, true)
	record_label.add_theme_color_override("font_color", Color("a9c2d8"))
	if not profile.warning.is_empty():
		UI.label(body, t(profile.warning), 24, true)
	UI.primary_button(body, "▶  BẮT ĐẦU RUN", func() -> void: launch(false), 98).grab_focus()
	UI.button(body, "⬆  Nâng cấp Player", show_player_upgrades, 70)
	UI.button(body, "⚙  " + t("settings"), show_settings, 70)
	UI.button(body, "?  " + t("help"), show_help, 70)
	UI.danger_button(body, t("quit"), func() -> void: get_tree().quit(), 64)
	UI.label(body, "1.0.0-rc.1  ·  OFFLINE", 20, true)

func show_player_upgrades() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("ffd166"))
	UI.label(header, "NÂNG CẤP PLAYER", 38, true)
	UI.label(body, "Vàng hiện có: %d  ·  Mỗi cấp tăng hiệu quả trong mọi trận" % profile.data.gold, 23, true)
	var labels := {"hp": "Máu tối đa  +15", "damage": "Damage  +5%", "armor": "Giáp  +1", "haste": "Tốc độ bắn  +5%"}
	for stat in ["hp", "damage", "armor", "haste"]:
		var level: int = int(dict_value(profile.data.meta_upgrades, stat, 0))
		var cost := 100 + level * 75
		var card := UI.card(body, Color("315976"))
		UI.label(card, "%s  ·  Cấp %d/20" % [labels[stat], level], 24, true)
		UI.button(card, "NÂNG CẤP  ·  %d VÀNG" % cost, func() -> void:
			if profile.upgrade_meta(stat):
				show_player_upgrades(), 70)

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
	match String(dict_value(result, "status", "")):
		"free":
			show_shop()
		"gold":
			show_shop()
		"payment":
			show_payment_popup(slot, rarity_index, int(dict_value(result, "cost", 0)))
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
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("character_menu"), 38, true)
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
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("map_menu"), 38, true)
	UI.label(body, "10 map · mỗi map 5 level · 3 loại quái/mức · 5 boss riêng", 23, true)
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
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("settings"), 38, true)
	UI.settings(body, profile, show_settings)

func show_help() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("help"), 38, true)
	var guide := UI.card(body, Color("315976"))
	UI.label(guide, t("help_body"), 23)

func show_back_button() -> void:
	subpage_active = true
	queue_redraw()
	back_button.text = "←  " + t("back")
	back_button.show()
	back_button.grab_focus()
