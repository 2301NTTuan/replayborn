extends Control

signal direction_changed(direction: Vector2)
const MIN_TOUCH_Y: float = 300.0
const RADIUS: float = 122.0
const DEADZONE: float = 0.08
var finger: int = -1
var direction: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO

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
	queue_redraw()

func reset() -> void:
	finger = -1
	direction = Vector2.ZERO
	center = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	# Deliberately invisible. Touch input remains active across the playfield.
	return
