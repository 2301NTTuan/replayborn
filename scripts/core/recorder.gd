extends RefCounted

const LENGTH: int = 900
var positions: PackedVector2Array = PackedVector2Array()
var shots: Array = []
var tick: int = 0

func begin(position: Vector2) -> void:
	positions = PackedVector2Array([position])
	shots = []
	tick = 0

func record(position: Vector2, fired: Array) -> bool:
	# Tick 0 is the first simulated tick. Exactly 900 ticks per 15s at 60Hz.
	positions.append(position)
	for shot in fired:
		shots.append({"tick": tick, "shot": shot.duplicate(true)})
	tick += 1
	return tick == LENGTH

func snapshot() -> Dictionary:
	return {"positions": positions.duplicate(), "shots": shots.duplicate(true)}
