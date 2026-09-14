extends Node2D
const DISPLAY_FONT = preload("res://assets/fonts/CascadiaCode.ttf")

var tape: Dictionary = {}
var tick: int = 0
var shot_index: int = 0
var arena_game: Node
var number: int = 1
var tint: Color = Color("86a8ff")
var character_index: int = 0
var gender: int = 0
var archetype: int = 0
var motion: Vector2 = Vector2.ZERO
var age: float = 0.0
var health: float = 55.0
var max_health: float = 55.0
var hurt_time: float = 0.0
var dead: bool = false
var spawn_protection: float = 1.5

func setup(recording: Dictionary, game: Node, serial: int) -> void:
	tape = recording
	arena_game = game
	number = serial
	position = tape.positions[0]
	tint = [Color("ff4fd8"), Color("ffd166"), Color("63f6ff")][game.profile.data.palette]
	character_index = game.profile.data.character
	gender = character_index % 2
	archetype = character_index / 2
	max_health = maxf(1.0, game.max_health * 0.70)
	health = max_health

func advance() -> bool:
	if tape.is_empty():
		return true
	age += 1.0 / 60.0
	hurt_time = maxf(0.0, hurt_time - 1.0 / 60.0)
	spawn_protection = maxf(0.0, spawn_protection - 1.0 / 60.0)
	var next_position: Vector2 = tape.positions[tick + 1]
	motion = next_position - position
	position = next_position
	while shot_index < tape.shots.size() and tape.shots[shot_index].tick == tick:
		var shot: Dictionary = tape.shots[shot_index].shot.duplicate(true)
		shot.ghost = true
		shot.damage *= shot.echo_multiplier
		arena_game.combat.add_shot(shot)
		shot_index += 1
	tick += 1
	if tick == 900:
		tick = 0
		shot_index = 0
	queue_redraw()
	# A live Echo loops its recorded tape. The next recording is held until this
	# Echo is destroyed, so a new clone never replaces one that is still fighting.
	return false

func take_damage(amount: int) -> void:
	if dead or spawn_protection > 0.0:
		return
	health = maxf(0.0, health - maxi(1, amount))
	hurt_time = 0.22
	if health <= 0:
		dead = true
	queue_redraw()

func _draw() -> void:
	if hurt_time > 0.0 and fmod(hurt_time * 30.0, 2.0) < 1.0:
		modulate = Color("ff4b61")
	else:
		modulate = Color.WHITE
	var health_ratio := clampf(health / max_health, 0.0, 1.0)
	draw_line(Vector2(-27, -48), Vector2(27, -48), Color("160d20", 0.85), 5)
	draw_line(Vector2(-27, -48), Vector2(-27 + 54 * health_ratio, -48), Color("ff647b"), 4)
	if spawn_protection > 0.0:
		draw_arc(Vector2.ZERO, 46.0 + sin(age * 12.0) * 3.0, 0, TAU, 32, Color("d7fbff", 0.82), 3)
	if has_node("ArtVisual"):
		draw_arc(Vector2.ZERO, 32, 0, TAU, 24, tint, 3)
		draw_string(DISPLAY_FONT, Vector2(-7, 7), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("b2c6ff"))
		return
	draw_circle(Vector2.ZERO, 25, Color(tint, 0.16))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 24, tint, 3)
	draw_circle(Vector2(0, -8), 10, Color(tint, 0.7))
	draw_line(Vector2(-12, 8), Vector2(12, 8), tint, 4)
	draw_string(DISPLAY_FONT, Vector2(-7, 7), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("b2c6ff"))
