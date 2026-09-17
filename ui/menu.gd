extends Control
const UI = preload("res://ui/ui_kit.gd")
const Art = preload("res://ui/title_art.gd")
const WORDMARK = preload("res://assets/ui/replayborn_wordmark.png")
var profile: Node
var body: VBoxContainer
var back_button: Button
var subpage_active: bool = false
var home_deck: Control
var launching: bool = false
var launch_veil: ColorRect

func dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func _ready() -> void:
	profile = get_node("/root/Profile")
	theme = UI.theme()
	body = UI.column(self, Rect2(64, 220, 952, 1570))
	var scroll: Control = body.get_parent()
	scroll.anchor_right = 1
	scroll.anchor_bottom = 1
	scroll.offset_right = -64
	scroll.offset_bottom = -80
	back_button = UI.button(self, "←  " + t("back"), show_home, 82)
	back_button.position = Vector2(54, 46)
	back_button.size = Vector2(196, 82)
	back_button.hide()
	resized.connect(queue_redraw)
	show_home()
	RenderingServer.set_default_clear_color(Color("050b14"))

func t(key: String) -> String:
	return UI.text(key, profile)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050b14"))

func clear_home() -> void:
	if is_instance_valid(home_deck):
		remove_child(home_deck)
		home_deck.queue_free()
		home_deck = null

func show_home() -> void:
	UI.clear(body)
	body.get_parent().hide()
	clear_home()
	home_deck = Control.new()
	home_deck.name = "TitleScreen"
	add_child(home_deck)
	home_deck.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	subpage_active = false
	back_button.hide()
	var art := Art.new()
	art.reduced = bool(profile.data.reduced)
	home_deck.add_child(art)
	var wordmark := Art.picture(WORDMARK)
	wordmark.name = "Wordmark"
	# Image canvas has transparent padding: an atlas removes only that padding.
	var letters := AtlasTexture.new()
	letters.atlas = WORDMARK
	letters.region = Rect2(0, 300, 1536, 440)
	wordmark.texture = letters
	Art.place(wordmark, home_deck, Rect2(0.07, 0.055, 0.86, 0.13))
	var vi: bool = profile.data.language == "vi"
	var subtitle := Art.caption("VIẾT LẠI VẬN MỆNH" if vi else "REWRITE YOUR FATE", 22, Color("b3d5e1"))
	Art.place(subtitle, home_deck, Rect2(0.1, 0.18, 0.8, 0.035))
	var play := Button.new()
	play.name = "Play"
	play.text = "CHƠI   ›" if vi else "PLAY   ›"
	play.add_theme_font_override("font", ThemeDB.fallback_font)
	play.add_theme_font_size_override("font_size", 36)
	play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := Color("d5f5f5")
		if state == "hover": fill = Color("ffffff")
		if state == "pressed": fill = Color("78cdd8")
		var box := UI.box(fill, 4, Color("ffffff"), 1)
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = Color("77f1ff")
			box.set_border_width_all(3)
			box.set_expand_margin_all(7)
		else:
			box.shadow_color = Color(0.12, 0.7, 0.85, 0.16)
			box.shadow_size = 24
		play.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		play.add_theme_color_override(state, Color("112a38"))
	play.pressed.connect(func() -> void: launch(false))
	Art.place(play, home_deck, Rect2(0.19, 0.825, 0.62, 0.064))
	play.grab_focus()
	var footer := Art.caption("R E P L A Y B O R N   /   " + str(ProjectSettings.get_setting("application/config/version")), 17, Color("7993a7"))
	Art.place(footer, home_deck, Rect2(0.08, 0.947, 0.84, 0.025))
	if not profile.data.reduced:
		home_deck.modulate.a = 0.0
		create_tween().tween_property(home_deck, "modulate:a", 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if subpage_active and event.is_action_pressed("ui_cancel"):
		show_home()
		get_viewport().set_input_as_handled()

func begin_subpage() -> void:
	clear_home()
	body.get_parent().show()
	body.show()

func show_player_upgrades() -> void:
	begin_subpage()
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("ffd166"))
	UI.label(header, t("meta_upgrades"), 38, true)
	UI.caption(body, "GOLD %d   ·   CORE %d" % [profile.data.gold, profile.data.upgrade_core], true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	body.add_child(grid)
	var labels := {"hp": t("meta_hp"), "damage": t("meta_damage"), "armor": t("meta_armor"), "haste": t("meta_haste")}
	for stat in ["hp", "damage", "armor", "haste"]:
		var level: int = int(dict_value(profile.data.meta_upgrades, stat, 0))
		var cost: Dictionary = profile.meta_cost(stat)
		var card := UI.card(grid, [Color("ff647b"), Color("ffd26a"), Color("72b8ff"), Color("72f6d4")][["hp", "damage", "armor", "haste"].find(stat)])
		card.get_parent().custom_minimum_size = Vector2(430, 238)
		UI.caption(card, "%s  %d/10" % [t("level_word"), level], true)
		UI.label(card, labels[stat], 23, true)
		UI.label(card, "NEXT  ·  ◆ %d  ◈ %d" % [cost.gold, cost.core], 18, true)
		var buy := UI.button(card, t("upgrade_action"), func() -> void:
			if profile.upgrade_meta(stat):
				show_player_upgrades(), 70)
		buy.disabled = level >= 10 or profile.data.gold < cost.gold or profile.data.upgrade_core < cost.core

func show_armory() -> void:
	begin_subpage()
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("armory"), 38, true)
	var rack := HBoxContainer.new()
	rack.add_theme_constant_override("separation", 16)
	body.add_child(rack)
	var names := [t("pulse"), t("scatter"), t("lance")]
	var finishers := [t("pulse_finisher"), t("scatter_finisher"), t("lance_finisher")]
	for index in range(3):
		var weapon_index: int = index
		var unlocked: bool = bool(profile.data.weapon_unlocks[index])
		var selected: bool = int(profile.data.weapon) == index
		var card := UI.card(rack, Color("55ebd2") if selected else Color("315976"))
		card.get_parent().custom_minimum_size = Vector2(295, 510)
		UI.caption(card, "WEAPON %02d" % (index + 1), true)
		UI.label(card, names[index], 28, true)
		UI.label(card, "AUTO FIRE", 17, true)
		UI.label(card, finishers[index], 19)
		if unlocked:
			var select := UI.button(card, t("selected") if selected else t("select"), func() -> void:
				profile.setting("weapon", weapon_index)
				show_armory(), 66)
			select.disabled = selected
		else:
			UI.label(card, t("weapon_locked_%d" % index), 20, true)

func launch(practice: bool) -> void:
	if launching:
		return
	launching = true
	profile.practice = practice
	launch_veil = ColorRect.new()
	launch_veil.color = Color("050b14")
	launch_veil.modulate.a = 0.0
	Art.place(launch_veil, self, Rect2(0, 0, 1, 1))
	var fade := create_tween()
	fade.tween_property(launch_veil, "modulate:a", 1.0, 0.08 if profile.data.reduced else 0.3)
	fade.tween_callback(_open_game)

func _open_game() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		launching = false
		launch_veil.queue_free()
		push_error("Cannot open gameplay: %s" % error)

func show_settings() -> void:
	begin_subpage()
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
	begin_subpage()
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
	begin_subpage()
	UI.clear(body)
	show_back_button()
	var header := UI.card(body, Color("55ebd2"))
	UI.label(header, t("help"), 38, true)
	var steps := [["01", "MOVE", "Drag anywhere to run."], ["02", "AUTO FIRE", "Weapon locks the closest target."], ["03", "TIME CIRCUIT", "Cross your Memory trail to close a circuit."], ["04", "CHRONO SHIFT", "Dash through danger and cut time."], ["05", "UPGRADE", "Choose a core after collecting XP."]]
	for step in steps:
		var card := UI.card(body, Color("72f6d4") if step[0] in ["03", "04"] else Color("315976"))
		UI.caption(card, step[0], true)
		UI.label(card, step[1], 25, true)
		UI.label(card, step[2], 19, true)

func show_back_button() -> void:
	subpage_active = true
	queue_redraw()
	back_button.text = "←  " + t("back")
	back_button.show()
	back_button.grab_focus()
