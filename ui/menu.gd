extends Control
const UI = preload("res://ui/ui_kit.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const CharacterThumb = preload("res://ui/character_thumb.gd")
const MapThumb = preload("res://ui/map_thumb.gd")
const HEROINE_SHEET = preload("res://assets/original_v1/astria_run_v1.png")
var profile: Node
var body: VBoxContainer
var back_button: Button
var subpage_active: bool = false

func _ready() -> void:
	profile = get_node("/root/Profile")
	theme = UI.theme()
	body = UI.column(self, Rect2(56, 742, 968, 1128))
	back_button = UI.button(self, "←  " + t("back"), show_home, 82)
	back_button.position = Vector2(54, 44)
	back_button.size = Vector2(210, 70)
	back_button.hide()
	show_home()
	RenderingServer.set_default_clear_color(Color("090f1d"))

func t(key: String) -> String:
	return UI.text(key, profile)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), Color("060b16"))
	draw_circle(Vector2(850, 240), 560, Color("113b50", 0.42))
	draw_circle(Vector2(855, 250), 370, Color("176a6c", 0.19))
	draw_circle(Vector2(90, 675), 280, Color("282456", 0.19))
	for index in range(7):
		draw_line(Vector2(0, 110 + index * 118), Vector2(1080, 0 + index * 118), Color("294b67", 0.13), 2)
	draw_rect(Rect2(30, 690, 1020, 1190), Color("091526", 0.96))
	draw_rect(Rect2(30, 690, 1020, 1190), Color("315976"), false, 2)
	draw_line(Vector2(55, 716), Vector2(1025, 716), Color("55ebd2"), 3)
	for index in range(4):
		draw_arc(Vector2(814, 336), 104 + index * 49, -PI * 0.92, PI * 0.63, 64, Color(0.33, 0.92, 0.82, 0.62 - index * 0.12), 3)
	draw_circle(Vector2(814, 336), 38, Color("55ebd2"))
	draw_circle(Vector2(814, 336), 16, Color("d9fff7"))
	draw_texture_rect_region(HEROINE_SHEET, Rect2(570, 170, 410, 545), Rect2(0, 0, HEROINE_SHEET.get_width() / 4, HEROINE_SHEET.get_height()), Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(56, 168), "REPLAYBORN", HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color("effbff"))
	draw_string(ThemeDB.fallback_font, Vector2(60, 212), "SURVIVE THE LOOP  /  COMMAND THE ECHOES", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("63e6d2"))
	draw_string(ThemeDB.fallback_font, Vector2(60, 310), "CHAPTER 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd26a"))
	draw_string(ThemeDB.fallback_font, Vector2(60, 365), "TÀN TÍCH NEON", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("eaf4ff"))
	draw_string(ThemeDB.fallback_font, Vector2(60, 402), "5 MỨC ĐỘ  •  5 BOSS  •  OFFLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("92acc4"))
	draw_rect(Rect2(60, 472, 430, 126), Color("10263c", 0.94))
	draw_rect(Rect2(60, 472, 430, 126), Color("386986"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(84, 512), "ASTRIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("effbff"))
	draw_string(ThemeDB.fallback_font, Vector2(84, 548), "ECHO RUNNER  ·  LV.01", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9bbbcf"))
	draw_string(ThemeDB.fallback_font, Vector2(84, 578), "WEAPON BONDED  ·  READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("55ebd2"))
	if subpage_active:
		# Opaque enough to separate secondary screens from the home hero, while
		# retaining a hint of the neon environment underneath.
		draw_rect(Rect2(0, 0, 1080, 1920), Color(0.015, 0.035, 0.065, 0.90))

func show_home() -> void:
	UI.clear(body)
	subpage_active = false
	queue_redraw()
	back_button.hide()
	UI.caption(body, "Trung tâm điều khiển", true)
	var status := UI.card(body, Color("315976"))
	UI.label(status, "HỒ SƠ CHIẾN DỊCH", 20, true)
	var record_label := UI.label(status, t("records") % [profile.data.runs, profile.data.wins, profile.data.kills], 24, true)
	record_label.add_theme_color_override("font_color", Color("a9c2d8"))
	if not profile.warning.is_empty():
		UI.label(body, t(profile.warning), 24, true)
	UI.primary_button(body, "▶  " + t("start"), func() -> void: launch(false), 112).grab_focus()
	UI.button(body, "⬆  Nâng cấp Player", show_player_upgrades, 78)
	UI.button(body, "⚙  " + t("settings"), show_settings, 78)
	UI.button(body, "?  " + t("help"), show_help, 78)
	UI.danger_button(body, t("quit"), func() -> void: get_tree().quit(), 72)
	UI.label(body, "1.0.0-rc.1  ·  OFFLINE", 23, true)

func show_player_upgrades() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("ffd166"))
	UI.label(header, "NÂNG CẤP PLAYER", 38, true)
	UI.label(body, "Vàng hiện có: %d  ·  Mỗi cấp tăng hiệu quả trong mọi trận" % profile.data.gold, 23, true)
	var labels := {"hp": "Máu tối đa  +15", "damage": "Damage  +5%", "armor": "Giáp  +1", "haste": "Tốc độ bắn  +5%"}
	for stat in ["hp", "damage", "armor", "haste"]:
		var level: int = int(profile.data.meta_upgrades.get(stat, 0))
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
