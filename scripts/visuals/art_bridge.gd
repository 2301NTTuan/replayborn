extends RefCounted

const CHARACTERS := [
    "vanguard_m", "vanguard_f", "runner_m", "runner_f", "tech_m", "tech_f",
    "warden_m", "warden_f", "duelist_m", "duelist_f"
]
const ArenaMap = preload("res://scripts/visuals/arena_map.gd")

var game: Node
var map_root: Node2D
var friendly_projectile: Texture2D
var hostile_projectile: Texture2D
var anime_enemy_frames: Dictionary = {}

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
    if index == 0:
        var anime_sprite := AnimatedSprite2D.new()
        anime_sprite.name = "ArtVisual"
        anime_sprite.sprite_frames = load("res://assets/original_v1/astria_sprite_frames.tres")
        anime_sprite.scale = Vector2(0.095, 0.095)
        anime_sprite.position = Vector2(0, -24)
        anime_sprite.z_index = 10
        player.add_child(anime_sprite)
        anime_sprite.play("idle")
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
    var visual := player.get_node_or_null("ArtVisual") as Node2D
    if visual == null:
        return
    var moving: bool = player.velocity.length_squared() > 1.0
    var sprite := visual as AnimatedSprite2D
    if sprite == null:
        return
    var wanted := &"run" if moving else &"idle"
    if sprite.animation != wanted:
        sprite.play(wanted)
    if absf(player.velocity.x) > 1.0:
        sprite.flip_h = player.velocity.x < 0.0

func get_anime_enemy_frames(id: String) -> SpriteFrames:
    if anime_enemy_frames.has(id):
        return anime_enemy_frames[id]
    var texture := load("res://assets/original_v1/%s_run_v1.png" % id) as Texture2D
    if texture == null:
        return null
    var frames := SpriteFrames.new()
    frames.remove_animation(&"default")
    frames.add_animation(&"idle")
    frames.set_animation_speed(&"idle", 1.0)
    frames.set_animation_loop(&"idle", true)
    frames.add_animation(&"run")
    frames.set_animation_speed(&"run", 10.0)
    frames.set_animation_loop(&"run", true)
    var frame_width: float = texture.get_width() / 4.0
    var frame_height: float = texture.get_height()
    for index in range(4):
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(frame_width * index, 0, frame_width, frame_height)
        frames.add_frame(&"run", atlas)
        if index == 0:
            frames.add_frame(&"idle", atlas)
    anime_enemy_frames[id] = frames
    return frames

func attach_enemy(enemy: Node2D) -> void:
    if enemy.has_node("ArtVisual") or enemy.spec == null:
        return
    var id := String(enemy.spec.id)
    if id in ["chaser", "runner", "charger", "shooter", "orbiter"] or id.begins_with("boss_"):
        var anime_sprite := AnimatedSprite2D.new()
        anime_sprite.name = "ArtVisual"
        anime_sprite.sprite_frames = get_anime_enemy_frames("archive_colossus" if id.begins_with("boss_") else "rift_crawler")
        var visual_scale: float = 0.15 if id.begins_with("boss_") else (0.08 if id == "charger" else 0.07)
        anime_sprite.scale = Vector2(visual_scale, visual_scale)
        if id.begins_with("boss_"):
            anime_sprite.modulate = enemy.spec.tint.lerp(Color.WHITE, 0.42)
        anime_sprite.z_index = 8
        enemy.add_child(anime_sprite)
        anime_sprite.play("run")
        return
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
    var visual := enemy.get_node_or_null("ArtVisual") as Node2D
    if visual == null:
        return
    var sprite := visual as AnimatedSprite2D
    if sprite == null:
        return
    if enemy.target != null:
        sprite.flip_h = enemy.target.position.x < enemy.position.x

func attach_echo(echo: Node2D) -> void:
    if echo.has_node("ArtVisual"):
        return
    var sprite := AnimatedSprite2D.new()
    sprite.name = "ArtVisual"
    sprite.sprite_frames = load("res://assets/original_v1/astria_sprite_frames.tres")
    sprite.position = Vector2(0, -24)
    sprite.scale = Vector2(0.095, 0.095)
    sprite.modulate = Color(echo.tint, 0.58)
    sprite.z_index = 7
    echo.add_child(sprite)
    sprite.play("idle")

func update_echo(echo: Node2D) -> void:
    var sprite := echo.get_node_or_null("ArtVisual") as AnimatedSprite2D
    if sprite == null:
        return
    var moving: bool = echo.motion.length_squared() > 1.0
    var wanted := &"run" if moving else &"idle"
    if sprite.animation != wanted:
        sprite.play(wanted)
    if absf(echo.motion.x) > 1.0:
        sprite.flip_h = echo.motion.x < 0.0

func setup_map(map_id: String) -> void:
    map_root = Node2D.new()
    map_root.name = "ArtMap"
    map_root.z_index = -100
    game.add_child(map_root)
    game.move_child(map_root, 0)
    var arena_map := ArenaMap.new()
    arena_map.configure(game.ARENA, game.map_data.background, game.map_data.accent, map_id)
    map_root.add_child(arena_map)
