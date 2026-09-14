extends Node2D

var kind: String = "heart"
var target: Node2D
var life: float = 0.0
var collected: bool = false

func setup(value: String, owner: Node2D) -> void:
	kind = value
	target = owner
	queue_redraw()

func advance(delta: float) -> bool:
	life += delta
	if not is_instance_valid(target):
		return true
	if global_position.distance_to(target.global_position) < 38.0:
		collected = true
		return true
	queue_redraw()
	return false

func _draw() -> void:
	var pulse := 1.0 + sin(life * 7.0) * 0.10
	if kind == "magnet":
		draw_circle(Vector2.ZERO, 22.0 * pulse, Color("66d9ff", 0.12))
		draw_circle(Vector2.ZERO, 13.0, Color("172d46"))
		draw_arc(Vector2.ZERO, 9.0, PI * 0.12, PI * 0.88, 18, Color("76e9ff"), 5.0)
		draw_line(Vector2(-9, 1), Vector2(-9, 8), Color("ff6b87"), 4.0)
		draw_line(Vector2(9, 1), Vector2(9, 8), Color("ff6b87"), 4.0)
	else:
		draw_circle(Vector2.ZERO, 22.0 * pulse, Color("ff5f7d", 0.12))
		draw_circle(Vector2.ZERO, 12.0, Color("ff5f7d"))
		draw_rect(Rect2(-3.0, -8.0, 6.0, 16.0), Color("fff5f7"))
		draw_rect(Rect2(-8.0, -3.0, 16.0, 6.0), Color("fff5f7"))
