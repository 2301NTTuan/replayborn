extends Control
## Shared, resolution-independent presentation for the title and boot scenes.
const ART = preload("res://assets/ui/astria_title.png")
const EMBLEM = preload("res://assets/ui/replayborn_emblem.png")
var elapsed: float = 0.0
var reduced: bool = false
var cinematic: bool = false
var scrim: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.24, 0.53, 0.75, 0.94, 1.0])
	gradient.colors = PackedColorArray([Color(0.015, 0.027, 0.05, 0.8), Color(0.015, 0.027, 0.05, 0.0), Color(0.015, 0.027, 0.05, 0.0), Color(0.015, 0.027, 0.05, 0.5), Color(0.015, 0.027, 0.05, 0.98), Color(0.015, 0.027, 0.05, 1.0)])
	scrim = GradientTexture2D.new()
	scrim.gradient = gradient
	scrim.width = 16
	scrim.height = 1024
	scrim.fill_from = Vector2(0, 0)
	scrim.fill_to = Vector2(0, 1)
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if not reduced:
		elapsed += delta
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050b14"))
	var factor: float = maxf(size.x / ART.get_width(), size.y / ART.get_height())
	var art_size := ART.get_size() * factor
	if not cinematic:
		draw_texture_rect(ART, Rect2((size - art_size) * 0.5, art_size), false)
	# Soft top/bottom scrims protect lettering while leaving Astria's face clear.
	if scrim != null:
		draw_texture_rect(scrim, Rect2(Vector2.ZERO, size), false)
	if reduced:
		return
	# A few slow time fragments; no flashing, busy overlays or face obstruction.
	for index in range(12):
		var x: float = fposmod(index * 0.618, 1.0) * size.x
		var y: float = fposmod(index * 0.137 - elapsed * 0.012, 1.0) * size.y
		var alpha: float = 0.12 + 0.16 * sin(elapsed * 0.7 + index)
		draw_line(Vector2(x, y), Vector2(x + 3, y - 9), Color(0.36, 0.91, 1, alpha), 1.4, true)

static func place(control: Control, parent: Control, rect: Rect2) -> void:
	parent.add_child(control)
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

static func picture(texture: Texture2D) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

static func caption(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
