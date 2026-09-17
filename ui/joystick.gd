extends Control

signal direction_changed(direction: Vector2)
const MIN_TOUCH_Y: float = 300.0
const RADIUS: float = 122.0
const DEADZONE: float = 0.08
var finger: int = -1
var direction: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO
var fade: float = 0.0
var render_feedback: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and finger == -1 and local.y >= MIN_TOUCH_Y:
			finger = event.index
			center = local
			update_direction(local)
		elif not event.pressed and event.index == finger:
			reset()
	elif event is InputEventScreenDrag and event.index == finger:
		update_direction(get_global_transform_with_canvas().affine_inverse() * event.position)

func update_direction(local: Vector2) -> void:
	var raw := ((local - center) / RADIUS).limit_length()
	if raw.length() < DEADZONE:
		direction = Vector2.ZERO
	else:
		var strength := (raw.length() - DEADZONE) / (1.0 - DEADZONE)
		direction = raw.normalized() * clampf(strength, 0.0, 1.0)
	direction_changed.emit(direction)
	fade = 1.0
	queue_redraw()

func reset() -> void:
	finger = -1
	direction = Vector2.ZERO
	center = Vector2.ZERO
	direction_changed.emit(direction)
	fade = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	fade = maxf(0.0, fade - delta * 1.45) if finger == -1 else 1.0
	queue_redraw()

func _draw() -> void:
	if not render_feedback or fade <= 0.01 or center == Vector2.ZERO:
		return
	var alpha := fade * (0.72 if finger != -1 else 0.32)
	draw_circle(center, RADIUS, Color(0.03, 0.10, 0.18, alpha * 0.64))
	draw_arc(center, RADIUS, 0.0, TAU, 40, Color(0.35, 0.92, 0.90, alpha), 3.0)
	draw_arc(center, RADIUS * 0.68, -PI * 0.35, PI * 1.15, 28, Color(0.68, 0.48, 1.0, alpha * 0.68), 2.0)
	var thumb := center + direction * RADIUS * 0.56
	draw_circle(thumb, 42.0, Color(0.25, 0.88, 0.90, alpha * 0.25))
	draw_circle(thumb, 28.0, Color(0.68, 0.96, 0.95, alpha * 0.76))
	draw_arc(thumb, 30.0, 0.0, TAU, 24, Color(0.92, 1.0, 1.0, alpha), 2.0)
