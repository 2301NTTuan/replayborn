extends CanvasLayer
const UI = preload("res://ui/ui_kit.gd")
const Joystick = preload("res://ui/joystick.gd")
var game: Node
var root_control: Control
var stats_label: Label
var gold_label: Label
var clock_label: Label
var health_label: Label
var echo_label: Label
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

func t(key: String) -> String:
	return UI.text(key, game.profile)

func hud_card(rect: Rect2, border: Color = Color("315976")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", UI.box(Color("0a1a2e", 0.96), 16, border, 2))
	root_control.add_child(panel)
	return panel

func bind_game(owner_game: Node) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.clip_contents = true
	root_control.theme = UI.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var backdrop := Panel.new()
	backdrop.position = Vector2(28, 22)
	backdrop.size = Vector2(1024, 330)
	backdrop.add_theme_stylebox_override("panel", UI.box(Color("061222", 0.82), 24, Color("264a67"), 2))
	root_control.add_child(backdrop)
	hud_card(Rect2(46, 38, 294, 82), Color("55ebd2"))
	hud_card(Rect2(354, 38, 258, 82), Color("315976"))
	hud_card(Rect2(626, 38, 164, 82), Color("ffd166"))
	hud_card(Rect2(46, 134, 986, 74), Color("315976"))
	hud_card(Rect2(46, 216, 986, 118), Color("315976"))
	var run_caption := UI.label(root_control, "RUN STATUS", 16)
	run_caption.position = Vector2(68, 49)
	run_caption.size = Vector2(240, 22)
	run_caption.add_theme_color_override("font_color", Color("55ebd2"))
	clock_label = UI.label(root_control, "00:00", 38, true)
	clock_label.position = Vector2(370, 51)
	clock_label.size = Vector2(226, 48)
	clock_label.add_theme_color_override("font_color", Color("effbff"))
	gold_label = UI.label(root_control, "", 22, true)
	gold_label.position = Vector2(638, 58)
	gold_label.size = Vector2(140, 42)
	gold_label.clip_text = true
	gold_label.add_theme_color_override("font_color", Color("ffd166"))
	stats_label = UI.label(root_control, "", 24)
	stats_label.position = Vector2(68, 75)
	stats_label.size = Vector2(250, 32)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.clip_text = true
	stats_label.add_theme_color_override("font_color", Color("aec4d7"))
	var vital_caption := UI.label(root_control, "VITAL // HP", 16)
	vital_caption.position = Vector2(66, 143)
	vital_caption.size = Vector2(220, 22)
	vital_caption.add_theme_color_override("font_color", Color("ff9eb1"))
	health_label = UI.label(root_control, "", 21)
	health_label.position = Vector2(765, 141)
	health_label.size = Vector2(240, 28)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	health_label.clip_text = true
	health_label.add_theme_color_override("font_color", Color("effbff"))
	health_label.add_theme_color_override("font_color", Color("ff91a5"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(66, 173)
	health_bar.size = Vector2(946, 16)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", UI.box(Color("210f22"), 8, Color("713348"), 1))
	health_bar.add_theme_stylebox_override("fill", UI.box(Color("ff637d"), 8))
	root_control.add_child(health_bar)
	var memory_caption := UI.label(root_control, "REPLAY MEMORY", 16)
	memory_caption.position = Vector2(66, 226)
	memory_caption.size = Vector2(250, 22)
	memory_caption.add_theme_color_override("font_color", Color("55ebd2"))
	echo_label = UI.label(root_control, "", 22)
	echo_label.position = Vector2(66, 251)
	echo_label.size = Vector2(455, 26)
	echo_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	echo_label.clip_text = true
	echo_label.add_theme_color_override("font_color", Color("b78cff"))
	xp_label = UI.label(root_control, "", 19)
	xp_label.position = Vector2(548, 251)
	xp_label.size = Vector2(464, 26)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	xp_label.clip_text = true
	xp_label.add_theme_color_override("font_color", Color("ffd26a"))
	progress = ProgressBar.new()
	progress.position = Vector2(66, 278)
	progress.size = Vector2(450, 6)
	progress.max_value = 900
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", UI.box(Color("15142b"), 8, Color("443b72"), 1))
	progress.add_theme_stylebox_override("fill", UI.box(Color("b78cff"), 8))
	root_control.add_child(progress)
	xp_progress = ProgressBar.new()
	xp_progress.position = Vector2(548, 278)
	xp_progress.size = Vector2(464, 6)
	xp_progress.show_percentage = false
	root_control.add_child(xp_progress)
	pause_button = UI.button(root_control, t("pause"), game.toggle_pause)
	pause_button.position = Vector2(812, 43)
	pause_button.size = Vector2(164, 82)
	pause_button.text = "Ⅱ  " + t("pause")
	joystick = Joystick.new()
	joystick.name = "Joystick"
	# The joystick is an invisible full-playfield touch layer with no visual.
	joystick.position = Vector2.ZERO
	joystick.size = Vector2(1080, 1920)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.direction_changed.connect(func(direction: Vector2) -> void: game.player.touch_direction = direction)
	root_control.add_child(joystick)
	announcement_panel = Panel.new()
	announcement_panel.position = Vector2(156, 344)
	announcement_panel.size = Vector2(768, 58)
	announcement_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	announcement_panel.add_theme_stylebox_override("panel", UI.box(Color("0b1d30", 0.94), 18, Color("b78cff", 0.58), 2))
	root_control.add_child(announcement_panel)
	announcement_panel.hide()
	announcement = UI.label(root_control, "", 25, true)
	announcement.position = Vector2(120, 354)
	announcement.size = Vector2(840, 64)
	announcement.autowrap_mode = TextServer.AUTOWRAP_OFF
	announcement.clip_text = true
	announcement.add_theme_color_override("font_color", Color("ffd26a"))
	pickup_label = UI.label(root_control, "", 24, true)
	pickup_label.position = Vector2(220, 302)
	pickup_label.size = Vector2(640, 40)
	boss_label = UI.label(root_control, "", 24, true)
	boss_label.position = Vector2(100, 402)
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
	# Keep the gameplay HUD inside a portrait safe area. The overlay and touch layer
	# use the full viewport and must not inherit this inset.
	for child in root_control.get_children():
		if child == joystick or child.name == "BottomHint":
			continue
		child.position.y += 42
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
	overlay_kicker = UI.label(overlay_panel, "SYSTEM / REPLAYBORN", 18, true)
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
	stats_label.text = "LV.%02d  •  K.O. %03d" % [game.director.stage + 1, game.kills]
	gold_label.text = "◆ %d" % game.profile.data.gold
	health_label.text = "%d / %d" % [ceili(game.health), int(game.max_health)]
	health_bar.max_value = game.max_health
	health_bar.value = game.health
	echo_label.text = "REC  %04.1fs / 15s   •   ECHO %d/4" % [game.recorder.tick / 60.0, game.echoes.size()]
	xp_label.text = "LV.%02d  •  EXP %d/%d" % [game.run_level, game.run_xp, game.xp_to_next]
	progress.value = game.recorder.tick
	xp_progress.max_value = game.xp_to_next
	xp_progress.value = game.run_xp
	if is_instance_valid(game.boss) and not game.boss.dead:
		var boss_name: String = game.boss.spec.title_en if game.profile.data.language == "en" else game.boss.spec.title_vi
		boss_label.text = "BOSS  /  %s   %d / %d HP" % [boss_name, ceili(game.boss.health), ceili(game.boss.max_health)]
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
	overlay_kicker.text = "SYSTEM / REPLAYBORN"
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
	overlay_kicker.text = "RUN PAUSED  /  SESSION SAFE"
	overlay_note("Dữ liệu vòng lặp hiện tại vẫn được giữ nguyên.")
	UI.primary_button(body, "▶  " + t("resume"), game.toggle_pause, 108).grab_focus()
	UI.button(body, "↻  " + t("restart"), func() -> void: confirm_exit(game.restart_run), 88)
	UI.button(body, "⚙  " + t("settings"), show_settings, 88)
	UI.button(body, "?  " + t("help"), show_help, 88)
	UI.danger_button(body, "⌂  " + t("home"), func() -> void: confirm_exit(game.return_home), 88)

func confirm_exit(action: Callable) -> void:
	show_overlay(t("abandon"))
	overlay_kicker.text = "CONFIRMATION REQUIRED"
	overlay_note("Kết thúc phiên sẽ xoá tiến trình trong trận hiện tại.")
	UI.danger_button(body, t("confirm"), action, 96)
	UI.button(body, t("cancel"), show_pause, 88).grab_focus()

func show_settings() -> void:
	show_overlay(t("settings"))
	overlay_kicker.text = "SYSTEM CONFIGURATION"
	UI.settings(body, game.profile, show_settings)
	UI.button(body, "←  " + t("back"), show_pause)

func show_help() -> void:
	show_overlay(t("help"))
	overlay_kicker.text = "FIELD MANUAL"
	var guide := UI.card(body, Color("315976"))
	UI.label(guide, t("help_body"), 27)
	UI.button(body, "←  " + t("back"), show_pause)

func show_tutorial() -> void:
	show_overlay(t("help"))
	overlay_kicker.text = "MISSION BRIEFING"
	var guide := UI.card(body, Color("315976"))
	UI.label(guide, t("help_body"), 27)
	UI.primary_button(body, "▶  " + t("ready"), game.begin_play, 104).grab_focus()

func show_upgrades(offers: Array) -> void:
	show_overlay("CHỌN LÕI" if game.profile.data.language == "vi" else "CHOOSE CORE")
	overlay_kicker.text = "LEVEL UP  /  SELECT ONE CORE"
	overlay_note("Bạn đã nhặt đủ EXP. Chạm một lõi để nâng cấp vòng lặp.")
	var accents := [Color("55ebd2"), Color("ffd26a"), Color("b78cff")]
	for index in range(offers.size()):
		var offer_index := index
		var item: Resource = offers[index]
		var english: bool = game.profile.data.language == "en"
		var title: String = item.title_en if english else item.title_vi
		var description: String = item.description_en if english else item.description_vi
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
		UI.caption(offer, "CORE %02d" % (index + 1))
		var title_label := UI.label(offer, title, 31)
		title_label.add_theme_color_override("font_color", accents[index % accents.size()])
		var description_label := UI.label(offer, description, 22)
		description_label.add_theme_color_override("font_color", Color("b7c9d9"))
		var tap_hint := UI.label(offer, "CHẠM VÀO THẺ ĐỂ CHỌN", 18, true)
		tap_hint.add_theme_color_override("font_color", accents[index % accents.size()])

func show_result() -> void:
	show_overlay(t("win" if game.won else "lose"))
	overlay_kicker.text = "RUN REPORT  /  ECHO ARCHIVE"
	var report := UI.card(body, Color("ffd26a") if game.won else Color("a95070"))
	UI.label(report, t("result") % [int(game.run_time) / 60, int(game.run_time) % 60, game.kills], 31, true)
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
