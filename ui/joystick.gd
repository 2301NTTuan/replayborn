extends Control

signal direction_changed(direction: Vector2)
const CENTER: Vector2 = Vector2(150, 150)
const RADIUS: float = 105.0
var finger: int = -1
var direction: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and finger == -1 and local.distance_to(CENTER) <= 145.0:
			finger = event.index
			update_direction(local)
		elif not event.pressed and event.index == finger:
			reset()
	elif event is InputEventScreenDrag and event.index == finger:
		update_direction(get_global_transform_with_canvas().affine_inverse() * event.position)

func update_direction(local: Vector2) -> void:
	direction = ((local - CENTER) / RADIUS).limit_length()
	if direction.length() < 0.15:
		direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func reset() -> void:
	finger = -1
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	draw_circle(CENTER, RADIUS, Color(0.3, 0.5, 0.7, 0.18))
	draw_arc(CENTER, RADIUS, 0, TAU, 48, Color(0.5, 0.7, 0.9, 0.55), 3)
	draw_circle(CENTER + direction * RADIUS, 40, Color(0.38, 0.92, 0.8, 0.6))
