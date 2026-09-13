extends RefCounted
const Words = preload("res://scripts/core/words.gd")

static func text(key: String, profile: Node) -> String:
	return Words.get_text(key, profile.data.language)

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 27
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("16283f") if state == "normal" else Color("254a62")
		if state == "pressed":
			box.bg_color = Color("316d7b")
		if state == "disabled":
			box.bg_color = Color("172030")
		box.set_corner_radius_all(18)
		box.set_content_margin_all(18)
		box.border_color = Color("6fffe0") if state == "focus" else Color("294b67")
		box.set_border_width_all(3 if state == "focus" else 2)
		result.set_stylebox(state, "Button", box)
	result.set_color("font_color", "Label", Color("dce7f4"))
	result.set_color("font_color", "Button", Color("edf6ff"))
	result.set_color("font_hover_color", "Button", Color("ffffff"))
	var background := StyleBoxFlat.new()
	background.bg_color = Color("25354c")
	background.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("62eacb")
	fill.set_corner_radius_all(6)
	result.set_stylebox("background", "ProgressBar", background)
	result.set_stylebox("fill", "ProgressBar", fill)
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

static func button(parent: Node, value: String, callback: Callable, height: float = 88) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size.y = height
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

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
	for key in ["volume", "music"]:
		label(parent, text(key, profile))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = profile.data[key]
		slider.custom_minimum_size.y = 65
		slider.value_changed.connect(func(value: float) -> void: profile.setting(key, value))
		parent.add_child(slider)
	var reduced := CheckButton.new()
	reduced.text = text("reduced", profile)
	reduced.custom_minimum_size.y = 80
	reduced.button_pressed = profile.data.reduced
	reduced.toggled.connect(func(value: bool) -> void: profile.setting("reduced", value))
	parent.add_child(reduced)
	label(parent, text("language", profile))
	var language := OptionButton.new()
	language.custom_minimum_size.y = 85
	language.add_item("Tiếng Việt")
	language.add_item("English")
	language.select(0 if profile.data.language == "vi" else 1)
	language.item_selected.connect(func(index: int) -> void:
		profile.setting("language", "vi" if index == 0 else "en")
		language_changed.call_deferred())
	parent.add_child(language)
	label(parent, "Màu bản sao" if profile.data.language == "vi" else "Echo color")
	var palette := OptionButton.new()
	palette.custom_minimum_size.y = 85
	var names: Array = ["Lam / Blue", "Vàng / Gold · 100 kills", "Tím / Violet · 1 win"]
	for index in range(3):
		palette.add_item(names[index])
		palette.set_item_disabled(index, not profile.palette_unlocked(index))
	palette.select(profile.data.palette)
	palette.item_selected.connect(func(index: int) -> void: profile.setting("palette", index))
	parent.add_child(palette)
