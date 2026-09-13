extends CanvasLayer
const UI = preload("res://ui/ui_kit.gd")
const Joystick = preload("res://ui/joystick.gd")
var game: Node
var root_control: Control
var stats_label: Label
var clock_label: Label
var echo_label: Label
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
var announcement_left: float = 0
var pause_button: Button
var pickup_label: Label
var pickup_left: float = 0.0

func t(key: String) -> String:
	return UI.text(key, game.profile)

func bind_game(owner_game: Node) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control = Control.new()
	root_control.theme = UI.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var top_panel := Panel.new()
	top_panel.position = Vector2(30, 24)
	top_panel.size = Vector2(1020, 288)
	top_panel.add_theme_stylebox_override("panel", UI.box(Color("09182a", 0.94), 22, Color("315976"), 2))
	root_control.add_child(top_panel)
	var top_line := ColorRect.new()
	top_line.position = Vector2(54, 304)
	top_line.size = Vector2(972, 3)
	top_line.color = Color("55ebd2")
	root_control.add_child(top_line)
	clock_label = UI.label(root_control, "00:00", 54)
	clock_label.position = Vector2(60, 42)
	clock_label.size = Vector2(520, 70)
	clock_label.add_theme_color_override("font_color", Color("effbff"))
	stats_label = UI.label(root_control, "", 24)
	stats_label.position = Vector2(62, 119)
	stats_label.size = Vector2(720, 42)
	stats_label.add_theme_color_override("font_color", Color("aec4d7"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(60, 171)
	health_bar.size = Vector2(960, 18)
	health_bar.show_percentage = false
	root_control.add_child(health_bar)
	echo_label = UI.label(root_control, "", 22)
	echo_label.position = Vector2(62, 204)
	echo_label.size = Vector2(960, 35)
	echo_label.add_theme_color_override("font_color", Color("a8c7d3"))
	progress = ProgressBar.new()
	progress.position = Vector2(60, 246)
	progress.size = Vector2(960, 13)
	progress.max_value = 900
	progress.show_percentage = false
	root_control.add_child(progress)
	xp_progress = ProgressBar.new()
	xp_progress.position = Vector2(60, 274)
	xp_progress.size = Vector2(960, 9)
	xp_progress.show_percentage = false
	root_control.add_child(xp_progress)
	pause_button = UI.button(root_control, t("pause"), game.toggle_pause)
	pause_button.position = Vector2(828, 47)
	pause_button.size = Vector2(188, 64)
	pause_button.text = "Ⅱ  " + t("pause")
	joystick = Joystick.new()
	joystick.name = "Joystick"
	# The joystick is an invisible full-playfield touch layer with no visual.
	joystick.position = Vector2.ZERO
	joystick.size = Vector2(1080, 1920)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.direction_changed.connect(func(direction: Vector2) -> void: game.player.touch_direction = direction)
	root_control.add_child(joystick)
	announcement = UI.label(root_control, "", 30, true)
	announcement.position = Vector2(110, 338)
	announcement.size = Vector2(860, 76)
	announcement.add_theme_color_override("font_color", Color("ffd26a"))
	pickup_label = UI.label(root_control, "", 24, true)
	pickup_label.position = Vector2(220, 315)
	pickup_label.size = Vector2(640, 40)
	boss_label = UI.label(root_control, "", 24, true)
	boss_label.position = Vector2(80, 425)
	boss_label.size = Vector2(920, 45)
	boss_label.add_theme_color_override("font_color", Color("ffb0cb"))
	var hint := UI.label(root_control, t("hint"), 23, true)
	hint.position = Vector2(50, 1840)
	hint.size = Vector2(980, 40)
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
	overlay_kicker = UI.label(overlay_panel, "SYSTEM / REPLAYBORN", 18, true)
	overlay_kicker.position = Vector2(46, 42)
	overlay_kicker.size = Vector2(904, 28)
	overlay_kicker.add_theme_color_override("font_color", Color("55ebd2"))
	overlay_title = UI.label(overlay_panel, "", 52, true)
	overlay_title.position = Vector2(46, 76)
	overlay_title.size = Vector2(904, 66)
	overlay_title.add_theme_color_override("font_color", Color("effbff"))
	body = UI.column(overlay_panel, Rect2(38, 194, 920, 1398))
	overlay.hide()
	refresh()

func refresh() -> void:
	clock_label.text = "%02d:%02d" % [int(game.run_time) / 60, int(game.run_time) % 60]
	stats_label.text = "%s  ·  HP %d / %d   ·   %s %d" % [t("level") % (game.director.stage + 1), ceili(game.health), int(game.max_health), t("kills"), game.kills]
	health_bar.max_value = game.max_health
	health_bar.value = game.health
	echo_label.text = "LV.%d  XP %d/%d   ·   %s  %04.1f / 15s   ·   ECHO %d/4" % [game.run_level, game.run_xp, game.xp_to_next, t("record"), game.recorder.tick / 60.0, game.echoes.size()]
	progress.value = game.recorder.tick
	xp_progress.max_value = game.xp_to_next
	xp_progress.value = game.run_xp
	if is_instance_valid(game.boss) and not game.boss.dead:
		var boss_name: String = game.boss.spec.title_en if game.profile.data.language == "en" else game.boss.spec.title_vi
		boss_label.text = "%s · %s  ·  %d / %d" % [t("boss"), boss_name, ceili(game.boss.health), ceili(game.boss.max_health)]
	else:
		boss_label.text = ""

func show_overlay(title: String) -> void:
	joystick.reset()
	joystick.hide()
	joystick.set_process_input(false)
	pause_button.disabled = true
	UI.clear(body)
	overlay_title.text = title
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
	show_overlay(t("choose"))
	overlay_kicker.text = "LEVEL UP  /  SELECT ONE AUGMENT"
	overlay_note("Chọn một nâng cấp để định hình vòng lặp hiện tại.")
	var accents := [Color("55ebd2"), Color("ffd26a"), Color("b78cff")]
	for index in range(offers.size()):
		var offer_index := index
		var item: Resource = offers[index]
		var english: bool = game.profile.data.language == "en"
		var title: String = item.title_en if english else item.title_vi
		var description: String = item.description_en if english else item.description_vi
		var offer := UI.card(body, accents[index % accents.size()])
		var offer_panel := offer.get_parent() as PanelContainer
		offer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		offer_panel.gui_input.connect(func(event: InputEvent) -> void:
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				game.apply_upgrade(offer_index))
		offer_panel.mouse_entered.connect(func() -> void:
			offer_panel.add_theme_stylebox_override("panel", UI.box(Color("17364c"), 22, accents[index % accents.size()], 3)))
		offer_panel.mouse_exited.connect(func() -> void:
			offer_panel.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, 22, accents[index % accents.size()], 2)))
		UI.caption(offer, "AUGMENT %02d" % (index + 1))
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

func _process(delta: float) -> void:
	if game == null:
		return
	if not get_tree().paused and game.state == game.State.PLAYING:
		announcement_left = maxf(0, announcement_left - delta)
		announcement.visible = announcement_left > 0
		pickup_left = maxf(0, pickup_left - delta)
		pickup_label.visible = pickup_left > 0
		if pickup_left <= 0:
			pickup_label.text = ""

func show_pickup(amount: int) -> void:
	pickup_label.text = "+%d XP" % amount
	pickup_left = 0.8

func _unhandled_key_input(event: InputEvent) -> void:
	if game == null or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		game.toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and game.state in [game.State.PLAYING, game.State.PAUSED, game.State.ENDED]:
		game.restart_run()
		get_viewport().set_input_as_handled()
