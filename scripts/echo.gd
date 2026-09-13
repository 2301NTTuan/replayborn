extends Node2D

var tape: Dictionary = {}
var tick: int = 0
var shot_index: int = 0
var arena_game: Node
var number: int = 1
var tint: Color = Color("86a8ff")
var character_index: int = 0
var gender: int = 0
var archetype: int = 0

func setup(recording: Dictionary, game: Node, serial: int) -> void:
	tape = recording
	arena_game = game
	number = serial
	position = tape.positions[0]
	tint = [Color("86a8ff"), Color("ffd166"), Color("ee9bfa")][game.profile.data.palette]
	character_index = game.profile.data.character
	gender = character_index % 2
	archetype = character_index / 2

func advance() -> void:
	if tape.is_empty():
		return
	position = tape.positions[tick + 1]
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

func _draw() -> void:
	if has_node("ArtVisual"):
		draw_arc(Vector2.ZERO, 32, 0, TAU, 24, tint, 3)
		draw_string(ThemeDB.fallback_font, Vector2(-7, 7), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("b2c6ff"))
		return
	draw_circle(Vector2.ZERO, 25, Color(tint, 0.16))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 24, tint, 3)
	draw_circle(Vector2(0, -8), 10, Color(tint, 0.7))
	draw_line(Vector2(-12, 8), Vector2(12, 8), tint, 4)
	draw_string(ThemeDB.fallback_font, Vector2(-7, 7), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("b2c6ff"))
