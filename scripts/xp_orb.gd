extends Node2D

var value: int = 1
var target: Node2D
var velocity := Vector2.ZERO
var life: float = 0.0
var collected: bool = false

func setup(amount: int, owner: Node2D) -> void:
	value = amount
	target = owner
	queue_redraw()

func advance(delta: float) -> bool:
	life += delta
	if not is_instance_valid(target):
		return true
	var distance := global_position.distance_to(target.global_position)
	if distance < 190:
		var direction := global_position.direction_to(target.global_position)
		velocity = velocity.move_toward(direction * (240.0 + (190.0 - distance) * 3.0), 900.0 * delta)
		global_position += velocity * delta
	if distance < 34:
		collected = true
		return true
	queue_redraw()
	return false

func _draw() -> void:
	var pulse := 1.0 + sin(life * 8.0) * 0.12
	draw_circle(Vector2.ZERO, 12.0 * pulse, Color(0.35, 0.95, 0.84, 0.16))
	draw_circle(Vector2.ZERO, 6.0 * pulse, Color("62eacb"))
	draw_circle(Vector2(-2, -2), 2.0, Color("eafffb"))
