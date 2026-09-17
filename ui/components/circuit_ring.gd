extends Control

var ratio: float = 0.0
var circuit_ready: bool = false
var phase: float = 0.0

func set_state(value: float, is_ready: bool) -> void:
	ratio = clampf(value, 0.0, 1.0)
	circuit_ready = is_ready
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var energy := Color("72f6d4") if not circuit_ready else Color("ffe3a3")
	draw_arc(center, radius, 0.0, TAU, 40, Color("11283b", 0.92), 6.0)
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 40, energy, 6.0)
	if circuit_ready:
		draw_arc(center, radius + 8.0 + sin(phase * 4.0) * 2.0, 0.0, TAU, 40, Color(energy, 0.34), 2.0)
	draw_circle(center, radius * 0.55, Color("091525", 0.92))
	draw_line(center + Vector2(-radius * 0.24, 0), center + Vector2(radius * 0.24, 0), energy, 3.0)
	draw_line(center + Vector2(0, -radius * 0.24), center + Vector2(0, radius * 0.24), energy, 3.0)
