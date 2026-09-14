extends RefCounted
const Words = preload("res://scripts/core/words.gd")
const DISPLAY_FONT = preload("res://assets/fonts/CascadiaCode.ttf")

const INK := Color("edf6ff")
const MUTED := Color("8a9caf")
const CYAN := Color("72f6d4")
const CYAN_DARK := Color("16806f")
const SURFACE := Color("0b1320")
const SURFACE_ALT := Color("142033")

static func text(key: String, profile: Node) -> String:
	return Words.get_text(key, profile.data.language)

static func box(color: Color, radius: int = 10, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.border_color = border
	result.set_border_width_all(border_width)
	result.set_content_margin_all(18)
	return result

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = DISPLAY_FONT
	result.default_font_size = 27
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var color := SURFACE_ALT
		if state == "hover": color = Color("1a2c45")
		elif state == "pressed": color = Color("145a61")
		elif state == "disabled": color = Color("172233")
		var border := CYAN if state == "focus" else Color("2a4058")
		result.set_stylebox(state, "Button", box(color, 10, border, 3 if state == "focus" else 1))
		var primary_color := CYAN_DARK
		if state == "hover": primary_color = Color("18a58f")
		elif state == "pressed": primary_color = Color("0d5c57")
		elif state == "disabled": primary_color = Color("1b3942")
		result.set_stylebox(state, "PrimaryButton", box(primary_color, 12, Color("ccfff5") if state == "focus" else CYAN, 3 if state == "focus" else 1))
		var danger_color := Color("582c45") if state == "normal" else Color("793552")
		result.set_stylebox(state, "DangerButton", box(danger_color, 10, Color("9b506f"), 1))
	result.set_type_variation("PrimaryButton", "Button")
	result.set_type_variation("DangerButton", "Button")
	result.set_color("font_color", "Label", INK)
	result.set_color("font_color", "Button", INK)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", Color("c9fff6"))
	result.set_color("font_disabled_color", "Button", MUTED)
	result.set_stylebox("normal", "OptionButton", box(SURFACE_ALT, 10, Color("2a4058"), 1))
	result.set_stylebox("hover", "OptionButton", box(Color("1a2c45"), 10, CYAN, 1))
	result.set_stylebox("focus", "OptionButton", box(Color("1a2c45"), 10, CYAN, 2))
	result.set_stylebox("background", "ProgressBar", box(Color("07111f"), 5, Color("20344b"), 1))
	result.set_stylebox("fill", "ProgressBar", box(CYAN, 5))
	return result

static func label(parent: Node, value: String, font_size: int = 28, centered: bool = false) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

static func caption(parent: Node, value: String, centered: bool = false) -> Label:
	var item := label(parent, value.to_upper(), 18, centered)
	item.add_theme_color_override("font_color", CYAN)
	return item

static func button(parent: Node, value: String, callback: Callable, height: float = 88) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size.y = height
	item.add_theme_font_size_override("font_size", 25)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

static func primary_button(parent: Node, value: String, callback: Callable, height: float = 104) -> Button:
	var item := button(parent, value, callback, height)
	item.theme_type_variation = &"PrimaryButton"
	item.add_theme_font_size_override("font_size", 30)
	return item

static func danger_button(parent: Node, value: String, callback: Callable, height: float = 88) -> Button:
	var item := button(parent, value, callback, height)
	item.theme_type_variation = &"DangerButton"
	return item

static func card(parent: Node, accent: Color = Color("315976")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(SURFACE, 10, accent, 1))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

static func column(parent: Node, rect: Rect2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var result := VBoxContainer.new()
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_constant_override("separation", 18)
	scroll.add_child(result)
	return result

static func settings(parent: Node, profile: Node, language_changed: Callable) -> void:
	var sound_card := card(parent)
	caption(sound_card, "Âm thanh / Audio")
	for key in ["volume", "music"]:
		label(sound_card, text(key, profile), 26)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = profile.data[key]
		slider.custom_minimum_size.y = 52
		slider.value_changed.connect(func(value: float) -> void: profile.setting(key, value))
		sound_card.add_child(slider)
	var access_card := card(parent)
	caption(access_card, "Trải nghiệm / Experience")
	var reduced := CheckButton.new()
	reduced.text = text("reduced", profile)
	reduced.custom_minimum_size.y = 62
	reduced.button_pressed = profile.data.reduced
	reduced.toggled.connect(func(value: bool) -> void: profile.setting("reduced", value))
	access_card.add_child(reduced)
	label(access_card, text("language", profile), 26)
	var language := OptionButton.new()
	language.custom_minimum_size.y = 76
	language.add_item("Tiếng Việt")
	language.add_item("English")
	language.select(0 if profile.data.language == "vi" else 1)
	language.item_selected.connect(func(index: int) -> void:
		profile.setting("language", "vi" if index == 0 else "en")
		language_changed.call_deferred())
	access_card.add_child(language)
	label(access_card, "Màu bản sao" if profile.data.language == "vi" else "Echo color", 26)
	var palette := OptionButton.new()
	palette.custom_minimum_size.y = 76
	var names: Array = ["Lam / Blue", "Vàng / Gold · 100 kills", "Tím / Violet · 1 win"]
	for index in range(3):
		palette.add_item(names[index])
		palette.set_item_disabled(index, not profile.palette_unlocked(index))
	palette.select(profile.data.palette)
	palette.item_selected.connect(func(index: int) -> void: profile.setting("palette", index))
	access_card.add_child(palette)
