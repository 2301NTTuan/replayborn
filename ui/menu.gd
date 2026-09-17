extends Control
const UI = preload("res://ui/ui_kit.gd")
const DISPLAY_FONT = preload("res://assets/fonts/CascadiaCode.ttf")
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
	draw_string(DISPLAY_FONT, Vector2(68, 205), t("tagline"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("72f6d4"))
	draw_string(DISPLAY_FONT, Vector2(68, 330), "NEON RUINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("edf6ff"))
	draw_string(DISPLAY_FONT, Vector2(70, 374), t("menu_status"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8fa7ba"))
	draw_rect(Rect2(64, 470, 438, 112), Color("0c1624", 0.82))
	draw_rect(Rect2(64, 470, 438, 112), Color("263c55"), false, 1)
	draw_line(Vector2(86, 498), Vector2(194, 498), Color("f2c45b"), 3)
	draw_string(DISPLAY_FONT, Vector2(86, 535), "ASTRIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("edf6ff"))
	draw_string(DISPLAY_FONT, Vector2(86, 565), t("runner_ready"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("9cb2c6"))
	if subpage_active:
		draw_rect(Rect2(0, 0, 1080, 1920), Color(0.012, 0.018, 0.032, 0.92))

func show_home() -> void:
	UI.clear(body)
	subpage_active = false
	queue_redraw()
	back_button.hide()
	UI.caption(body, t("run_dock"), true)
	var status := UI.card(body, Color("2a4058"))
	UI.label(status, t("profile"), 18, true)
	UI.label(status, "◆ %d   ◈ %d" % [profile.data.gold, profile.data.upgrade_core], 24, true)
	var record_label := UI.label(status, t("records") % [profile.data.runs, profile.data.wins, profile.data.kills], 22, true)
	record_label.add_theme_color_override("font_color", Color("a9c2d8"))
	if not profile.warning.is_empty():
		UI.label(body, t(profile.warning), 24, true)
	UI.primary_button(body, "▶  " + t("play"), func() -> void: launch(false), 98).grab_focus()
	UI.button(body, "⌁  " + t("armory"), show_armory, 70)
	UI.button(body, "⬆  " + t("meta_upgrades"), show_player_upgrades, 70)
	UI.button(body, "◎  " + t("practice"), func() -> void: launch(true), 70)
	UI.button(body, "⚙  " + t("settings"), show_settings, 70)
	UI.button(body, "?  " + t("help"), show_help, 70)
	UI.danger_button(body, t("quit"), func() -> void: get_tree().quit(), 64)
	UI.label(body, "0.5.0-alpha.1  ·  " + t("offline"), 20, true)

func show_player_upgrades() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("ffd166"))
	UI.label(header, t("meta_upgrades"), 38, true)
	UI.label(body, "◆ %d   ◈ %d" % [profile.data.gold, profile.data.upgrade_core], 23, true)
	var labels := {"hp": t("meta_hp"), "damage": t("meta_damage"), "armor": t("meta_armor"), "haste": t("meta_haste")}
	for stat in ["hp", "damage", "armor", "haste"]:
		var level: int = int(dict_value(profile.data.meta_upgrades, stat, 0))
		var cost: Dictionary = profile.meta_cost(stat)
		var card := UI.card(body, Color("315976"))
		UI.label(card, "%s  ·  %s %d/10" % [labels[stat], t("level_word"), level], 24, true)
		var buy := UI.button(card, "%s  ·  ◆ %d + ◈ %d" % [t("upgrade_action"), cost.gold, cost.core], func() -> void:
			if profile.upgrade_meta(stat):
				show_player_upgrades(), 70)
		buy.disabled = level >= 10 or profile.data.gold < cost.gold or profile.data.upgrade_core < cost.core

func show_armory() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("armory"), 38, true)
	var names := [t("pulse"), t("scatter"), t("lance")]
	var finishers := [t("pulse_finisher"), t("scatter_finisher"), t("lance_finisher")]
	for index in range(3):
		var weapon_index: int = index
		var unlocked: bool = bool(profile.data.weapon_unlocks[index])
		var selected: bool = int(profile.data.weapon) == index
		var card := UI.card(body, Color("55ebd2") if selected else Color("315976"))
		UI.label(card, names[index], 30, true)
		UI.label(card, finishers[index], 21)
		if unlocked:
			var select := UI.button(card, t("selected") if selected else t("select"), func() -> void:
				profile.setting("weapon", weapon_index)
				show_armory(), 66)
			select.disabled = selected
		else:
			UI.label(card, t("weapon_locked_%d" % index), 20, true)

func launch(practice: bool) -> void:
	profile.practice = practice
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func show_settings() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("settings"), 38, true)
	UI.settings(body, profile, show_settings)
	UI.button(body, t("reset_tutorial"), func() -> void:
		profile.setting("tutorial", false)
		show_settings(), 64)
	UI.button(body, t("credits"), show_credits, 64)
	UI.danger_button(body, t("reset_progress"), confirm_reset_progress, 64)

func show_credits() -> void:
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("credits"), 38, true)
	UI.label(body, t("credits_body"), 21)

func confirm_reset_progress() -> void:
	var first := ConfirmationDialog.new()
	first.title = t("reset_progress")
	first.dialog_text = t("reset_warning_1")
	add_child(first)
	first.confirmed.connect(func() -> void:
		first.queue_free()
		confirm_reset_progress_final())
	first.canceled.connect(first.queue_free)
	first.popup_centered(Vector2(760, 300))

func confirm_reset_progress_final() -> void:
	var final_dialog := ConfirmationDialog.new()
	final_dialog.title = t("reset_confirm_title")
	final_dialog.dialog_text = t("reset_warning_2")
	add_child(final_dialog)
	final_dialog.confirmed.connect(func() -> void:
		profile.reset_progress()
		final_dialog.queue_free()
		show_home())
	final_dialog.canceled.connect(final_dialog.queue_free)
	final_dialog.popup_centered(Vector2(760, 300))

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
