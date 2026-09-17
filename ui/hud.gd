extends CanvasLayer
const UI = preload("res://ui/ui_kit.gd")
const Joystick = preload("res://ui/joystick.gd")
var game: Node
var root_control: Control
var stats_label: Label
var gold_label: Label
var clock_label: Label
var health_label: Label
var memory_label: Label
var xp_label: Label
var boss_label: Label
var progress: ProgressBar
var xp_progress: ProgressBar
var health_bar: ProgressBar
var joystick: Control
var overlay: ColorRect
var overlay_panel: Panel
var overlay_title: Label
var overlay_kicker: Label
var body: VBoxContainer
var announcement: Label
var announcement_panel: Panel
var announcement_left: float = 0
var pause_button: Button
var pickup_label: Label
var pickup_left: float = 0.0

func dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
	return source[key] if source.has(key) else fallback

func t(key: String) -> String:
	return UI.text(key, game.profile)

func apply_contrast(enabled: bool) -> void:
	if root_control == null:
		return
	for node in root_control.find_children("*", "Control", true, false):
		if node is Label or node is Button:
			node.add_theme_constant_override("outline_size", 4 if enabled else 0)
			node.add_theme_color_override("font_outline_color", Color.BLACK)

func hud_card(rect: Rect2, border: Color = Color("315976")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", UI.box(Color("08111f", 0.90), 9, border, 1))
	root_control.add_child(panel)
	return panel

func compact_pause_button(parent: Control) -> Button:
	var button := Button.new()
	button.text = "Ⅱ  " + t("pause")
	button.position = Vector2(796, 8)
	button.size = Vector2(182, 56)
	button.custom_minimum_size = Vector2(182, 56)
	button.add_theme_font_size_override("font_size", 17)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := Color("102238")
		if state == "hover": fill = Color("17324d")
		elif state == "pressed": fill = Color("1b4d5a")
		var style := UI.box(fill, 7, Color("40627d"), 1)
		style.set_content_margin_all(0)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(game.toggle_pause)
	parent.add_child(button)
	return button

func bind_game(owner_game: Node) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.clip_contents = true
	root_control.theme = UI.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	# The HUD intentionally has no enclosing box. It reads as a light tactical
	# overlay instead of a heavy window sitting over the game world.
	var run_panel := hud_card(Rect2(36, 16, 1008, 116), Color("315c78"))
	run_panel.clip_contents = true
	# These controls are deliberately parented to Run Status. Their local
	# coordinates cannot escape that panel when the HUD is resized or retuned.
	var replay_panel := Panel.new()
	replay_panel.position = Vector2(692, 8)
	replay_panel.size = Vector2(86, 56)
	replay_panel.add_theme_stylebox_override("panel", UI.box(Color("181126", 0.96), 8, Color("70528f"), 1))
	run_panel.add_child(replay_panel)
	var run_caption := UI.label(root_control, t("run_status"), 16)
	run_caption.position = Vector2(58, 27)
	run_caption.size = Vector2(220, 18)
	run_caption.add_theme_font_size_override("font_size", 14)
	run_caption.add_theme_color_override("font_color", Color("7ff5d8"))
	clock_label = UI.label(root_control, "00:00", 38, true)
	clock_label.position = Vector2(350, 27)
	clock_label.size = Vector2(140, 40)
	clock_label.add_theme_font_size_override("font_size", 28)
	clock_label.add_theme_color_override("font_color", Color("effbff"))
	gold_label = UI.label(root_control, "", 22, true)
	gold_label.position = Vector2(510, 34)
	gold_label.size = Vector2(124, 28)
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.clip_text = true
	gold_label.add_theme_color_override("font_color", Color("f2c45b"))
	stats_label = UI.label(root_control, "", 24)
	stats_label.position = Vector2(58, 48)
	stats_label.size = Vector2(280, 22)
	stats_label.add_theme_font_size_override("font_size", 17)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.clip_text = true
	stats_label.add_theme_color_override("font_color", Color("c0d2df"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(22, 80)
	health_bar.size = Vector2(458, 18)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", UI.box(Color("172235"), 6, Color("315976"), 1))
	health_bar.add_theme_stylebox_override("fill", UI.box(Color("ff647b"), 6, Color("ff9aaa"), 0))
	run_panel.add_child(health_bar)
	xp_progress = ProgressBar.new()
	xp_progress.position = Vector2(498, 80)
	xp_progress.size = Vector2(480, 18)
	xp_progress.show_percentage = false
	xp_progress.add_theme_stylebox_override("background", UI.box(Color("172235"), 6, Color("315976"), 1))
	xp_progress.add_theme_stylebox_override("fill", UI.box(Color("55ebd2"), 6, Color("9ffff0"), 0))
	run_panel.add_child(xp_progress)
	var memory_caption := UI.label(run_panel, t("memory"), 14, true)
	memory_caption.position = Vector2(702, 13)
	memory_caption.size = Vector2(66, 16)
	memory_caption.add_theme_font_size_override("font_size", 13)
	memory_caption.add_theme_color_override("font_color", Color("e4dbff"))
	memory_label = UI.label(run_panel, "", 22)
	memory_label.position = Vector2(694, 31)
	memory_label.size = Vector2(82, 26)
	memory_label.add_theme_font_size_override("font_size", 18)
	memory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	memory_label.clip_text = true
	memory_label.add_theme_color_override("font_color", Color("72f6d4"))
	pause_button = compact_pause_button(run_panel)
	joystick = Joystick.new()
	joystick.name = "Joystick"
	# The joystick is an invisible full-playfield touch layer with no visual.
	joystick.position = Vector2.ZERO
	joystick.size = Vector2(1080, 1920)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.direction_changed.connect(func(direction: Vector2) -> void: game.player.touch_direction = direction)
	root_control.add_child(joystick)
	announcement_panel = Panel.new()
	announcement_panel.position = Vector2(156, 218)
	announcement_panel.size = Vector2(768, 58)
	announcement_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	announcement_panel.add_theme_stylebox_override("panel", UI.box(Color("0b1d30", 0.94), 18, Color("b78cff", 0.58), 2))
	root_control.add_child(announcement_panel)
	announcement_panel.hide()
	announcement = UI.label(root_control, "", 25, true)
	announcement.position = Vector2(120, 228)
	announcement.size = Vector2(840, 64)
	announcement.autowrap_mode = TextServer.AUTOWRAP_OFF
	announcement.clip_text = true
	announcement.add_theme_color_override("font_color", Color("ffd26a"))
	pickup_label = UI.label(root_control, "", 24, true)
	pickup_label.position = Vector2(220, 185)
	pickup_label.size = Vector2(640, 40)
	boss_label = UI.label(root_control, "", 24, true)
	boss_label.position = Vector2(100, 284)
	boss_label.size = Vector2(880, 38)
	boss_label.add_theme_font_size_override("font_size", 19)
	boss_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss_label.clip_text = true
	boss_label.add_theme_color_override("font_color", Color("ffb0cb"))
	var hint := UI.label(root_control, t("hint"), 23, true)
	hint.name = "BottomHint"
	hint.position = Vector2(70, 1846)
	hint.size = Vector2(940, 30)
	hint.add_theme_font_size_override("font_size", 17)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.clip_text = true
	hint.add_theme_color_override("font_color", Color("7894ad"))
	overlay = ColorRect.new()
	overlay.color = Color(0.012, 0.026, 0.055, 0.96)
	overlay.size = Vector2(1080, 1920)
	root_control.add_child(overlay)
	for index in range(6):
		var beam := ColorRect.new()
		beam.position = Vector2(0, 120 + index * 270)
		beam.size = Vector2(1080, 1)
		beam.color = Color("54d8d1", 0.10)
		overlay.add_child(beam)
	overlay_panel = Panel.new()
	overlay_panel.position = Vector2(42, 130)
	overlay_panel.size = Vector2(996, 1660)
	overlay_panel.add_theme_stylebox_override("panel", UI.box(Color("09182b", 0.97), 30, Color("39627d"), 2))
	overlay.add_child(overlay_panel)
	var cyan_rule := ColorRect.new()
	cyan_rule.position = Vector2(34, 154)
	cyan_rule.size = Vector2(928, 3)
	cyan_rule.color = Color("55ebd2")
	overlay_panel.add_child(cyan_rule)
	overlay_kicker = UI.label(overlay_panel, t("system_brand"), 18, true)
	overlay_kicker.position = Vector2(46, 42)
	overlay_kicker.size = Vector2(904, 28)
	overlay_kicker.add_theme_color_override("font_color", Color("55ebd2"))
	overlay_title = UI.label(overlay_panel, "", 42, true)
	overlay_title.position = Vector2(46, 76)
	overlay_title.size = Vector2(904, 82)
	overlay_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	overlay_title.clip_text = true
	overlay_title.add_theme_color_override("font_color", Color("effbff"))
	body = UI.column(overlay_panel, Rect2(38, 194, 920, 1398))
	overlay.hide()
	refresh()

func refresh() -> void:
	clock_label.text = "%02d:%02d" % [int(game.run_time) / 60, int(game.run_time) % 60]
	var level_data: Resource = game.Catalog.LEVELS[mini(game.director.stage, game.Catalog.LEVELS.size() - 1)]
	var level_name: String = level_data.title_en if game.profile.data.language == "en" else level_data.title_vi
	stats_label.text = "L%d  %s · %s" % [game.director.stage + 1, level_name, t(String(game.weapon.id))]
	gold_label.text = "◆ +%d" % game.run_gold
	health_bar.max_value = game.max_health
	health_bar.value = game.health + game.shield
	xp_progress.max_value = game.xp_to_next
	xp_progress.value = game.run_xp
	memory_label.text = t("memory_ready") if game.circuit.snap_point != Vector2.INF else "%d%%" % roundi(game.circuit.memory_ratio(game.run_time) * 100.0)
	if is_instance_valid(game.boss) and not game.boss.dead:
		var boss_name: String = game.boss.spec.title_en if game.profile.data.language == "en" else game.boss.spec.title_vi
		boss_label.text = t("boss_hp") % [boss_name, ceili(game.boss.health), ceili(game.boss.max_health)]
	else:
		boss_label.text = ""

func show_overlay(title: String) -> void:
	joystick.reset()
	joystick.hide()
	joystick.set_process_input(false)
	pause_button.disabled = true
	UI.clear(body)
	overlay_title.text = title
	overlay_title.add_theme_font_size_override("font_size", 36 if title.length() > 22 else 42)
	overlay_kicker.text = t("system_brand")
	overlay.show()

func overlay_note(value: String) -> void:
	var note := UI.label(body, value, 20, true)
	note.add_theme_color_override("font_color", Color("91abc1"))

func close_overlay() -> void:
	overlay.hide()
	joystick.show()
	joystick.set_process_input(true)
	pause_button.disabled = false
	pause_button.text = "Ⅱ  " + t("pause")

func show_pause() -> void:
	show_overlay(t("pause"))
	overlay_kicker.text = t("paused_kicker")
	overlay_note(t("pause_note"))
	UI.primary_button(body, "▶  " + t("resume"), game.toggle_pause, 108).grab_focus()
	UI.button(body, "↻  " + t("restart"), func() -> void: confirm_exit(game.restart_run), 88)
	UI.button(body, "⚙  " + t("settings"), show_settings, 88)
	UI.button(body, "?  " + t("help"), show_help, 88)
	UI.danger_button(body, "⌂  " + t("home"), func() -> void: confirm_exit(game.return_home), 88)

func confirm_exit(action: Callable) -> void:
	show_overlay(t("abandon"))
	overlay_kicker.text = t("confirm_kicker")
	overlay_note(t("abandon_note"))
	UI.danger_button(body, t("confirm"), action, 96)
	UI.button(body, t("cancel"), show_pause, 88).grab_focus()

func show_settings() -> void:
	show_overlay(t("settings"))
	overlay_kicker.text = t("settings_kicker")
	UI.settings(body, game.profile, show_settings)
	UI.button(body, "←  " + t("back"), show_pause)

func show_help() -> void:
	show_overlay(t("help"))
	overlay_kicker.text = t("manual_kicker")
	var guide := UI.card(body, Color("315976"))
	UI.label(guide, t("help_body"), 27)
	UI.button(body, "←  " + t("back"), show_pause)

func show_tutorial() -> void:
	show_overlay(t("help"))
	overlay_kicker.text = t("tutorial_kicker")
	var guide := UI.card(body, Color("315976"))
	UI.label(guide, t("tutorial_intro"), 27)
	UI.primary_button(body, "▶  " + t("ready"), game.begin_play, 104).grab_focus()
	UI.button(body, t("skip_tutorial"), game.skip_tutorial, 78)

func show_tutorial_complete() -> void:
	show_overlay(t("tutorial_complete_title"))
	overlay_kicker.text = t("tutorial_kicker")
	var guide := UI.card(body, Color("55ebd2"))
	UI.label(guide, t("tutorial_complete"), 27)
	UI.primary_button(body, "▶  " + t("play"), game.finish_tutorial, 104).grab_focus()

func show_upgrades(offers: Array) -> void:
	show_overlay(t("choose_core"))
	overlay_kicker.text = t("upgrade_kicker")
	overlay_note(t("upgrade_note"))
	var accents := [Color("55ebd2"), Color("ffd26a"), Color("b78cff")]
	for index in range(offers.size()):
		var offer_index := index
		var item: Resource = offers[index]
		var english: bool = game.profile.data.language == "en"
		var title: String = item.title_en if english else item.title_vi
		var description: String = item.description_en if english else item.description_vi
		if item.core_type == "weapon":
			description += "  " + "★".repeat(int(dict_value(game.upgrade_counts, item.id, 0)) + 1)
		var offer := UI.card(body, accents[index % accents.size()])
		var offer_panel := offer.get_parent() as PanelContainer
		offer_panel.modulate.a = 0.0
		offer_panel.scale = Vector2(0.72, 0.72)
		var reveal := offer_panel.create_tween()
		reveal.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reveal.tween_interval(0.12 * index)
		reveal.set_parallel(true)
		reveal.tween_property(offer_panel, "modulate:a", 1.0, 0.28)
		reveal.tween_property(offer_panel, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		offer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		offer_panel.gui_input.connect(func(event: InputEvent) -> void:
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				game.apply_upgrade(offer_index))
		offer_panel.mouse_entered.connect(func() -> void:
			offer_panel.add_theme_stylebox_override("panel", UI.box(Color("17364c"), 22, accents[index % accents.size()], 3)))
		offer_panel.mouse_exited.connect(func() -> void:
			offer_panel.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, 22, accents[index % accents.size()], 2)))
		UI.caption(offer, t("core_index") % (index + 1))
		var title_label := UI.label(offer, title, 31)
		title_label.add_theme_color_override("font_color", accents[index % accents.size()])
		var description_label := UI.label(offer, description, 22)
		description_label.add_theme_color_override("font_color", Color("b7c9d9"))
		var tap_hint := UI.label(offer, t("tap_select"), 18, true)
		tap_hint.add_theme_color_override("font_color", accents[index % accents.size()])

func show_result() -> void:
	show_overlay(t("win" if game.won else "lose"))
	overlay_kicker.text = t("result_kicker")
	var report := UI.card(body, Color("ffd26a") if game.won else Color("a95070"))
	UI.label(report, t("result") % [int(game.run_time) / 60, int(game.run_time) % 60, game.kills], 31, true)
	UI.label(report, t("circuit_result") % [game.director.stage + 1, game.circuits_closed, game.enemies_captured, game.director.boss_defeated, game.run_gold, game.run_cores], 22)
	if not game.profile.warning.is_empty():
		UI.label(body, t(game.profile.warning), 25)
	UI.primary_button(body, "↻  " + t("restart"), game.restart_run, 100).grab_focus()
	UI.button(body, "⌂  " + t("home"), game.return_home)

func announce(key: String) -> void:
	announcement.text = t(key) % (game.director.stage + 1) if key in ["boss_arrives", "level_cleared"] else t(key)
	announcement_left = 2.5
	announcement_panel.show()
	announcement.show()

func _process(delta: float) -> void:
	if game == null:
		return
	if not get_tree().paused and game.state == game.State.PLAYING:
		announcement_left = maxf(0, announcement_left - delta)
		announcement.visible = announcement_left > 0
		announcement_panel.visible = announcement_left > 0
		pickup_left = maxf(0, pickup_left - delta)
		pickup_label.visible = pickup_left > 0
		if pickup_left <= 0:
			pickup_label.text = ""

func show_pickup(amount: int, gold: bool = false) -> void:
	# Resource totals are shown persistently in the top HUD; no floating pickup text.
	pickup_label.text = ""
	pickup_left = 0.0
	pickup_label.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if game == null or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		game.toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and game.state in [game.State.PLAYING, game.State.PAUSED, game.State.ENDED]:
		game.restart_run()
		get_viewport().set_input_as_handled()
