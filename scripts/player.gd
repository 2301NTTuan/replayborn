extends CharacterBody2D

var arena: Rect2 = Rect2(50, 310, 980, 1510)
var active: bool = true
var touch_direction: Vector2 = Vector2.ZERO
var speed: float = 420.0
var hurt_time: float = 0.0
var reduced_effects: bool = false

func advance(delta: float) -> void:
	hurt_time = maxf(0, hurt_time - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction.length_squared() > direction.length_squared():
		direction = touch_direction
	velocity = direction * speed if active else Vector2.ZERO
	move_and_slide()
	position = position.clamp(arena.position + Vector2.ONE * 25, arena.end - Vector2.ONE * 25)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 25, Color("62eacb"))
	draw_arc(Vector2.ZERO, 31, 0, TAU, 32, Color("cafff1"), 3)
	if hurt_time > 0:
		draw_arc(Vector2.ZERO, 39, 0, TAU, 32, Color("ff647b"), 5)
		if not reduced_effects:
			draw_circle(Vector2.ZERO, 25, Color(1, 0.4, 0.5, clampf(hurt_time, 0, 0.7)))
	if velocity.length_squared() > 0:
		draw_line(Vector2.ZERO, velocity.normalized() * 36, Color.WHITE, 4)
