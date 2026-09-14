extends Node2D

var value: int = 1
var target: Node2D
var velocity := Vector2.ZERO
var life: float = 0.0
var collected: bool = false
var magnet_left: float = 0.0

func setup(amount: int, owner: Node2D) -> void:
	value = amount
	target = owner
	queue_redraw()

func advance(delta: float) -> bool:
	life += delta
	magnet_left = maxf(0.0, magnet_left - delta)
	if not is_instance_valid(target): return true
	var distance := global_position.distance_to(target.global_position)
	var pickup_radius: float = 480.0 if magnet_left > 0.0 else 190.0
	if distance < pickup_radius:
		var pull_speed: float = 980.0 if magnet_left > 0.0 else 420.0
		velocity = velocity.move_toward(global_position.direction_to(target.global_position) * pull_speed, 1800.0 * delta if magnet_left > 0.0 else 1000.0 * delta)
		global_position += velocity * delta
	if distance < 34:
		collected = true
		return true
	queue_redraw()
	return false

func magnetize() -> void:
	magnet_left = 2.5

func _draw() -> void:
	var pulse := 1.0 + sin(life * 8.0) * 0.12
	draw_circle(Vector2.ZERO, 15.0 * pulse, Color("ffd166", 0.16))
	draw_circle(Vector2.ZERO, 8.0 * pulse, Color("ffd166"))
	draw_circle(Vector2(-2, -2), 2.5, Color("fff4b0"))
