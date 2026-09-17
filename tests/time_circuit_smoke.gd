extends SceneTree

const TimeCircuit = preload("res://scripts/core/time_circuit.gd")
var failures: int = 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var circuit = TimeCircuit.new()
	circuit.reset(Vector2.ZERO, 0.0)
	for tick in range(60):
		circuit.advance(Vector2.ZERO, tick / 60.0, 1.0 / 60.0, [])
	check(circuit.points.size() == 1, "standing still does not duplicate points")
	circuit.advance(Vector2(20, 0), 0.2, 1.0 / 60.0, [])
	circuit.advance(Vector2(40, 0), 7.0, 1.0 / 60.0, [])
	check(circuit.points.size() <= 2, "old points expire")
	circuit.reset(Vector2(100, 100), 0.0)
	var route := [Vector2(500, 100), Vector2(500, 500), Vector2(100, 500), Vector2(100, 80)]
	var closure: Dictionary = {}
	for index in range(route.size()):
		closure = circuit.advance(route[index], float(index + 1), 1.0 / 60.0, [])
	check(not closure.is_empty() and closure.polygon.size() >= 4, "valid path creates one polygon")
	var count: int = circuit.closures
	circuit.advance(Vector2(100, 100), 4.05, 1.0 / 60.0, [])
	check(circuit.closures == count, "one intersection cannot trigger twice")
	var small := TimeCircuit.new()
	small.reset(Vector2.ZERO, 0.0)
	for index in range(4):
		small.advance([Vector2(30, 0), Vector2(30, 30), Vector2(0, 30), Vector2(0, -5)][index], float(index + 1), 1.0 / 60.0, [])
	check(small.closures == 0, "small polygon rejected")
	var inside := Node2D.new()
	inside.position = Vector2(250, 250)
	inside.set_meta("dead", false)
	var outside := Node2D.new()
	outside.position = Vector2(700, 700)
	# Use lightweight objects with required gameplay fields.
	inside.set_script(load("res://scripts/enemy.gd"))
	outside.set_script(load("res://scripts/enemy.gd"))
	inside.dead = false
	inside.spawn_protection = 0.0
	outside.dead = false
	outside.spawn_protection = 0.0
	var selected: Array = circuit.select_targets(PackedVector2Array([Vector2(0,0), Vector2(500,0), Vector2(500,500), Vector2(0,500)]), [inside, outside])
	check(selected.size() == 1 and selected[0] == inside, "inside target selected and outside rejected")
	inside.free()
	outside.free()
	print("TIME CIRCUIT CHECKS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
