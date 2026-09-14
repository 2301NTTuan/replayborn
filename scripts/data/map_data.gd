extends Resource
@export var id: String
@export var title_vi: String
@export var title_en: String
@export var subtitle_vi: String
@export var subtitle_en: String
@export var background: Color = Color("111c30")
@export var accent: Color = Color("62eacb")
@export var enemy_order: Array[int] = [0, 1, 2, 3, 4]
@export var spawn_scale: float = 1.0
@export var boss_scale: float = 1.0

func enemies_for_stage(stage: int) -> Array[int]:
	if id == "neon_ruins":
		var first := 10 + clampi(stage, 0, 4) * 3
		return [first, first + 1, first + 2]
	# Every level uses a fixed trio. The map's order changes the trio and its rhythm.
	var result: Array[int] = []
	if enemy_order.is_empty():
		return result
	var start := posmod(stage, enemy_order.size())
	for offset in range(mini(3, enemy_order.size())):
		result.append(enemy_order[(start + offset) % enemy_order.size()])
	return result
