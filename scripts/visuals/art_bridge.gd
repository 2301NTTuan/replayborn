extends RefCounted

const ArenaMap = preload("res://scripts/visuals/arena_map.gd")

var game: Node
var map_root: Node2D
var friendly_projectile: Texture2D
var hostile_projectile: Texture2D
var anime_enemy_frames: Dictionary = {}

func _init(owner_game: Node) -> void:
    game = owner_game

func _dict_value(source: Dictionary, key: Variant, fallback: Variant) -> Variant:
    return source[key] if source.has(key) else fallback

func setup() -> void:
    attach_player(game.player, 0)
    setup_map(String(game.map_data.id))
    # Projectiles are procedural so the release does not depend on pack assets
    # whose commercial license has not been established.
    friendly_projectile = null
    hostile_projectile = null

func draw_projectiles(canvas: Node2D) -> void:
    if game.combat == null:
        return
    if friendly_projectile == null or hostile_projectile == null:
        for bullet in game.combat.friendly:
            if String(_dict_value(bullet, "secondary_id", "")) == "":
                canvas.draw_circle(bullet.position, 7.0 if not bullet.ghost else 5.0, Color("a8edff", 0.72) if bullet.ghost else Color("ffe59c"))
        for bullet in game.combat.hostile:
            canvas.draw_circle(bullet.position, 9.0, Color("ff536d"))
        return
    var fsize := Vector2(28, 28)
    for bullet in game.combat.friendly:
        if String(_dict_value(bullet, "secondary_id", "")) != "":
            continue
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
        anime_sprite.scale = Vector2(0.13, 0.13)
        anime_sprite.position = Vector2(0, -24)
        anime_sprite.z_index = 10
        player.add_child(anime_sprite)
        anime_sprite.play("idle")
        return
    # The vertical slice ships Astria only; future character art remains outside
    # the release runtime until it has gameplay support and clearance.

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
    if absf(player.facing.x) > 0.05:
        sprite.flip_h = player.facing.x < 0.0
    sprite.modulate = Color("ff4b61") if player.hurt_time > 0.0 and fmod(player.hurt_time * 30.0, 2.0) < 1.0 else Color.WHITE

func get_anime_enemy_frames(id: String) -> SpriteFrames:
    if anime_enemy_frames.has(id):
        return anime_enemy_frames[id]
    var texture := load("res://assets/original_v1/%s_run_v1.png" % id) as Texture2D
    if texture == null:
        return null
    var frames := SpriteFrames.new()
    frames.remove_animation(&"default")
    var frame_width: float = texture.get_width() / 4.0
    var frame_height: float = texture.get_height()
    var poses := {"idle": [0], "run": [0, 1, 2, 3], "windup": [1], "attack": [2], "hurt": [3], "death": [3]}
    for state in poses:
        frames.add_animation(state)
        frames.set_animation_speed(state, 10.0 if state == "run" else 5.0)
        frames.set_animation_loop(state, state in ["idle", "run"])
        for index in poses[state]:
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(frame_width * index, 0, frame_width, frame_height)
            frames.add_frame(state, atlas)
    anime_enemy_frames[id] = frames
    return frames

func attach_enemy(enemy: Node2D) -> void:
    if enemy.has_node("ArtVisual") or enemy.spec == null:
        return
    if enemy.spec.family >= 0:
        var creature := AnimatedSprite2D.new()
        creature.name = "ArtVisual"
        creature.sprite_frames = roster_frames(enemy.spec.family)
        creature.position = Vector2(0, -12)
        creature.scale = Vector2.ONE * (enemy.radius * 2.8 / 132.0)
        creature.z_index = 8
        enemy.add_child(creature)
        creature.play("idle")
        return
    var id := String(enemy.spec.id)
    if id.begins_with("boss_"):
        var boss_sprite := AnimatedSprite2D.new()
        boss_sprite.name = "ArtVisual"
        boss_sprite.sprite_frames = boss_frames(id)
        var cell_width: float = boss_sprite.sprite_frames.get_frame_texture("idle", 0).get_width()
        boss_sprite.scale = Vector2.ONE * (enemy.radius * 3.2 / cell_width)
        boss_sprite.position = Vector2(0, -enemy.radius * 0.3)
        boss_sprite.z_index = 8
        enemy.add_child(boss_sprite)
        boss_sprite.play("idle")
        return
    if id in ["chaser", "runner", "charger", "shooter", "orbiter"]:
        var anime_sprite := AnimatedSprite2D.new()
        anime_sprite.name = "ArtVisual"
        anime_sprite.sprite_frames = get_anime_enemy_frames("rift_crawler")
        var visual_scale: float = 0.08 if id == "charger" else 0.07
        anime_sprite.scale = Vector2(visual_scale, visual_scale)
        var colors := {"chaser": Color("f5a3bd"), "runner": Color("65e9ff"), "charger": Color("ffc05c"), "shooter": Color("ba8bff"), "orbiter": Color("83ef8c")}
        anime_sprite.modulate = colors[id]
        anime_sprite.speed_scale = 1.5 if id == "runner" else (0.75 if id == "charger" else 1.0)
        anime_sprite.z_index = 8
        enemy.add_child(anime_sprite)
        anime_sprite.play("run")
        return
    # Non-roster legacy definitions render procedurally in enemy.gd.

func update_enemy(enemy: Node2D) -> void:
    var visual := enemy.get_node_or_null("ArtVisual") as Node2D
    if visual == null:
        return
    var sprite := visual as AnimatedSprite2D
    if sprite == null:
        return
    var wanted: StringName = &"hurt" if enemy.flash > 0 and not enemy.dead else enemy.animation_state
    if sprite.sprite_frames.has_animation(wanted) and sprite.animation != wanted:
        sprite.play(wanted)
    sprite.modulate = Color("ff8585") if wanted == &"hurt" else Color.WHITE
    if enemy.dead:
        sprite.modulate.a = clampf(enemy.death_left / 0.42, 0.0, 1.0)
    elif enemy.spawn_protection > 0:
        var spawn_duration := 2.0 if String(enemy.spec.id).begins_with("boss_") else 0.7
        sprite.modulate.a = clampf(1.0 - enemy.spawn_protection / spawn_duration, 0.15, 1.0)
    if not enemy.dead and is_instance_valid(enemy.target):
        sprite.flip_h = enemy.target.position.x < enemy.position.x

func boss_frames(id: String) -> SpriteFrames:
    var key := "boss_art_" + id
    if anime_enemy_frames.has(key):
        return anime_enemy_frames[key]
    var texture := load("res://assets/original_v1/bosses/%s_v2.png" % id) as Texture2D
    var cell := Vector2(texture.get_width() / 4.0, texture.get_height() / 2.0)
    var frames := SpriteFrames.new()
    frames.remove_animation(&"default")
    var poses := {"idle": [0], "run": [1, 2], "windup": [3], "attack": [4], "hurt": [5], "death": [6, 7]}
    for state in poses:
        frames.add_animation(state)
        frames.set_animation_speed(state, 7.0 if state == "run" else 5.0)
        frames.set_animation_loop(state, state in ["run", "idle"])
        for index in poses[state]:
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(Vector2(index % 4, floori(float(index) / 4.0)) * cell, cell)
            frames.add_frame(state, atlas)
    anime_enemy_frames[key] = frames
    return frames

func roster_frames(family: int) -> SpriteFrames:
    var key := "roster_%d" % family
    if anime_enemy_frames.has(key):
        return anime_enemy_frames[key]
    var texture := load("res://assets/original_v1/enemy_roster_v2.png") as Texture2D
    # Generated atlas row heights follow each creature's silhouette, not a uniform grid.
    var rows := [0, 108, 210, 313, 423, 547, 664, 763, 888, 1020, 1189, 1315, 1465, 1593, 1765, 1983]
    var frames := SpriteFrames.new()
    frames.remove_animation(&"default")
    var poses := {"idle": [0], "run": [1, 0, 2, 0], "windup": [3], "attack": [4], "hurt": [3], "death": [4, 5]}
    for state in poses:
        frames.add_animation(state)
        frames.set_animation_speed(state, 10.0 if state == "run" else 5.0)
        frames.set_animation_loop(state, state in ["run", "idle"])
        for column in poses[state]:
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(float(column) * texture.get_width() / 6.0, rows[family], texture.get_width() / 6.0, rows[family + 1] - rows[family])
            frames.add_frame(state, atlas)
    anime_enemy_frames[key] = frames
    return frames

func setup_map(map_id: String) -> void:
    map_root = Node2D.new()
    map_root.name = "ArtMap"
    map_root.z_index = -100
    game.add_child(map_root)
    game.move_child(map_root, 0)
    var arena_map := ArenaMap.new()
    arena_map.configure(game.ARENA, game.map_data.background, game.map_data.accent, map_id)
    map_root.add_child(arena_map)
