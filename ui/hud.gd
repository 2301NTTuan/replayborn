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
	var top_panel := ColorRect.new()
	top_panel.position = Vector2(35, 28)
	top_panel.size = Vector2(1010, 275)
	top_panel.color = Color(0.035, 0.08, 0.14, 0.92)
	root_control.add_child(top_panel)
	var top_line := ColorRect.new()
	top_line.position = Vector2(35, 298)
	top_line.size = Vector2(1010, 4)
	top_line.color = Color("62eacb")
	root_control.add_child(top_line)
	clock_label = UI.label(root_control, "00:00", 52)
	clock_label.position = Vector2(60, 45)
	clock_label.size = Vector2(680, 70)
	stats_label = UI.label(root_control, "", 27)
	stats_label.position = Vector2(60, 122)
	stats_label.size = Vector2(920, 44)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(60, 172)
	health_bar.size = Vector2(960, 15)
	health_bar.show_percentage = false
	root_control.add_child(health_bar)
	echo_label = UI.label(root_control, "", 25)
	echo_label.position = Vector2(60, 200)
	echo_label.size = Vector2(960, 35)
	progress = ProgressBar.new()
	progress.position = Vector2(60, 246)
	progress.size = Vector2(960, 12)
	progress.max_value = 900
	progress.show_percentage = false
	root_control.add_child(progress)
	xp_progress = ProgressBar.new()
	xp_progress.position = Vector2(60, 270)
	xp_progress.size = Vector2(960, 10)
	xp_progress.show_percentage = false
	root_control.add_child(xp_progress)
	pause_button = UI.button(root_control, t("pause"), game.toggle_pause)
	pause_button.position = Vector2(815, 45)
	pause_button.size = Vector2(205, 68)
	joystick = Joystick.new()
	joystick.name = "Joystick"
	# The joystick is an invisible full-playfield touch layer with no visual.
	joystick.position = Vector2.ZERO
	joystick.size = Vector2(1080, 1920)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.direction_changed.connect(func(direction: Vector2) -> void: game.player.touch_direction = direction)
	root_control.add_child(joystick)
	announcement = UI.label(root_control, "", 30, true)
	announcement.position = Vector2(80, 335)
	announcement.size = Vector2(920, 90)
	pickup_label = UI.label(root_control, "", 24, true)
	pickup_label.position = Vector2(220, 305)
	pickup_label.size = Vector2(640, 40)
	boss_label = UI.label(root_control, "", 25, true)
	boss_label.position = Vector2(80, 425)
	boss_label.size = Vector2(920, 45)
	var hint := UI.label(root_control, t("hint"), 23, true)
	hint.position = Vector2(50, 1850)
	hint.size = Vector2(980, 40)
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.045, 0.085, 0.97)
	overlay.size = Vector2(1080, 1920)
	root_control.add_child(overlay)
	body = UI.column(overlay, Rect2(115, 275, 850, 1410))
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
		boss_label.text = "%s  ·  %d / %d" % [t("boss"), ceili(game.boss.health), ceili(game.boss.max_health)]
	else:
		boss_label.text = ""

func show_overlay(title: String) -> void:
	joystick.reset()
	joystick.hide()
	joystick.set_process_input(false)
	pause_button.disabled = true
	UI.clear(body)
	overlay.show()
	UI.label(body, title, 46, true)

func close_overlay() -> void:
	overlay.hide()
	joystick.show()
	joystick.set_process_input(true)
	pause_button.disabled = false
	pause_button.text = t("pause")

func show_pause() -> void:
	show_overlay(t("pause"))
	UI.button(body, t("resume"), game.toggle_pause).grab_focus()
	UI.button(body, t("restart"), func() -> void: confirm_exit(game.restart_run))
	UI.button(body, t("settings"), show_settings)
	UI.button(body, t("help"), show_help)
	UI.button(body, t("home"), func() -> void: confirm_exit(game.return_home))

func confirm_exit(action: Callable) -> void:
	show_overlay(t("abandon"))
	UI.button(body, t("confirm"), action)
	UI.button(body, t("cancel"), show_pause).grab_focus()

func show_settings() -> void:
	show_overlay(t("settings"))
	UI.settings(body, game.profile, show_settings)
	UI.button(body, t("back"), show_pause)

func show_help() -> void:
	show_overlay(t("help"))
	UI.label(body, t("help_body"), 29)
	UI.button(body, t("back"), show_pause)

func show_tutorial() -> void:
	show_overlay(t("help"))
	UI.label(body, t("help_body"), 29)
	UI.button(body, t("ready"), game.begin_play).grab_focus()

func show_upgrades(offers: Array) -> void:
	show_overlay(t("choose"))
	for index in range(offers.size()):
		var item: Resource = offers[index]
		var english: bool = game.profile.data.language == "en"
		var title: String = item.title_en if english else item.title_vi
		var description: String = item.description_en if english else item.description_vi
		UI.button(body, title, func() -> void: game.apply_upgrade(index), 110)
		UI.label(body, description, 27)

func show_result() -> void:
	show_overlay(t("win" if game.won else "lose"))
	UI.label(body, t("result") % [int(game.run_time) / 60, int(game.run_time) % 60, game.kills], 32, true)
	if not game.profile.warning.is_empty():
		UI.label(body, t(game.profile.warning), 25)
	UI.button(body, t("restart"), game.restart_run).grab_focus()
	UI.button(body, t("home"), game.return_home)

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
