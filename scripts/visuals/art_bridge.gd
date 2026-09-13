extends RefCounted

const CHARACTERS := [
    "vanguard_m", "vanguard_f", "runner_m", "runner_f", "tech_m", "tech_f",
    "warden_m", "warden_f", "duelist_m", "duelist_f"
]

var game: Node
var map_root: Node2D
var friendly_projectile: Texture2D
var hostile_projectile: Texture2D

func _init(owner_game: Node) -> void:
    game = owner_game

func setup() -> void:
    attach_player(game.player, int(game.profile.data.character))
    setup_map(String(game.map_data.id))
    friendly_projectile = load("res://assets/replayborn/weapons/%s/projectile.png" % String(game.weapon.id))
    hostile_projectile = load("res://assets/replayborn/weapons/hostile/projectile.png")

func draw_projectiles(canvas: Node2D) -> void:
    if friendly_projectile == null or hostile_projectile == null or game.combat == null:
        return
    var fsize := Vector2(28, 28)
    for bullet in game.combat.friendly:
        var mod := Color(0.58, 0.66, 1.0, 0.72) if bullet.ghost else Color.WHITE
        canvas.draw_texture_rect(friendly_projectile, Rect2(bullet.position - fsize * 0.5, fsize), false, mod)
    var hsize := Vector2(30, 30)
    for bullet in game.combat.hostile:
        canvas.draw_texture_rect(hostile_projectile, Rect2(bullet.position - hsize * 0.5, hsize), false)

func attach_player(player: Node2D, index: int) -> void:
    if player.has_node("ArtVisual"):
        return
    var sprite := AnimatedSprite2D.new()
    sprite.name = "ArtVisual"
    sprite.sprite_frames = load("res://assets/replayborn/characters/%s/sprite_frames.tres" % CHARACTERS[clampi(index, 0, 9)])
    sprite.position = Vector2(0, -4)
    sprite.scale = Vector2(0.82, 0.82)
    sprite.z_index = 10
    player.add_child(sprite)
    sprite.play("idle")
    _attach_equipment_overlays(player)

func _attach_equipment_overlays(player: Node2D) -> void:
    var rarity_names := ["common", "rare", "legendary", "mythic", "ancient"]
    var slots := [["ÁO", "shirt"], ["QUẦN", "pants"], ["GIÀY", "boots"], ["GIÁP", "armor"], ["VŨ KHÍ", "weapon"]]
    for entry in slots:
        var item: Dictionary = player.equipment.get(entry[0], {})
        if item.is_empty():
            continue
        var rarity := clampi(int(item.get("rarity", 0)), 0, 4)
        var overlay := Sprite2D.new()
        overlay.name = "Equip_%s" % entry[1]
        overlay.texture = load("res://assets/replayborn/equipment/overlays/%s/%s.png" % [rarity_names[rarity], entry[1]])
        overlay.position = Vector2(0, -4)
        overlay.scale = Vector2(0.82, 0.82)
        overlay.z_index = 11
        player.add_child(overlay)

func update_player(player: Node2D) -> void:
    var sprite := player.get_node_or_null("ArtVisual") as AnimatedSprite2D
    if sprite == null:
        return
    var moving: bool = player.velocity.length_squared() > 1.0
    var wanted := &"run" if moving else &"idle"
    if sprite.animation != wanted:
        sprite.play(wanted)
    if absf(player.velocity.x) > 1.0:
        sprite.flip_h = player.velocity.x < 0.0

func attach_enemy(enemy: Node2D) -> void:
    if enemy.has_node("ArtVisual") or enemy.spec == null:
        return
    var id := String(enemy.spec.id)
    var sprite := AnimatedSprite2D.new()
    sprite.name = "ArtVisual"
    sprite.sprite_frames = load("res://assets/replayborn/enemies/%s/sprite_frames.tres" % id)
    var base_size := 72.0 if id == "boss" else 48.0
    var s := clampf(enemy.radius / base_size * 1.7, 0.65, 1.65)
    sprite.scale = Vector2(s, s)
    sprite.z_index = 8
    if enemy.elite == 1:
        sprite.modulate = Color(1.15, 1.05, 0.75, 1.0)
    elif enemy.elite == 2:
        sprite.modulate = Color(0.75, 1.15, 1.15, 1.0)
    enemy.add_child(sprite)
    sprite.play("run")

func update_enemy(enemy: Node2D) -> void:
    var sprite := enemy.get_node_or_null("ArtVisual") as AnimatedSprite2D
    if sprite == null:
        return
    if enemy.target != null:
        sprite.flip_h = enemy.target.position.x < enemy.position.x

func attach_echo(echo: Node2D) -> void:
    if echo.has_node("ArtVisual"):
        return
    var sprite := AnimatedSprite2D.new()
    sprite.name = "ArtVisual"
    sprite.sprite_frames = load("res://assets/replayborn/characters/%s/sprite_frames.tres" % CHARACTERS[clampi(echo.character_index, 0, 9)])
    sprite.position = Vector2(0, -4)
    sprite.scale = Vector2(0.82, 0.82)
    sprite.modulate = Color(echo.tint, 0.58)
    sprite.z_index = 7
    echo.add_child(sprite)
    sprite.play("run")

func setup_map(map_id: String) -> void:
    map_root = Node2D.new()
    map_root.name = "ArtMap"
    map_root.z_index = -100
    game.add_child(map_root)
    game.move_child(map_root, 0)

    var floor := TextureRect.new()
    floor.position = game.ARENA.position
    floor.size = game.ARENA.size
    floor.texture = load("res://assets/replayborn/maps/%s/floor_tile.png" % map_id)
    floor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    floor.stretch_mode = TextureRect.STRETCH_TILE
    floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_root.add_child(floor)

    var rng := RandomNumberGenerator.new()
    rng.seed = abs(hash(map_id))
    for i in range(12):
        var prop := Sprite2D.new()
        prop.texture = load("res://assets/replayborn/maps/%s/prop_%02d.png" % [map_id, (i % 4) + 1])
        var edge := i % 4
        var p := Vector2.ZERO
        if edge == 0:
            p = Vector2(rng.randf_range(game.ARENA.position.x + 55, game.ARENA.end.x - 55), game.ARENA.position.y + rng.randf_range(30, 95))
        elif edge == 1:
            p = Vector2(rng.randf_range(game.ARENA.position.x + 55, game.ARENA.end.x - 55), game.ARENA.end.y - rng.randf_range(30, 95))
        elif edge == 2:
            p = Vector2(game.ARENA.position.x + rng.randf_range(30, 80), rng.randf_range(game.ARENA.position.y + 120, game.ARENA.end.y - 120))
        else:
            p = Vector2(game.ARENA.end.x - rng.randf_range(30, 80), rng.randf_range(game.ARENA.position.y + 120, game.ARENA.end.y - 120))
        prop.position = p
        prop.modulate.a = 0.70
        prop.scale = Vector2(0.72, 0.72)
        map_root.add_child(prop)
