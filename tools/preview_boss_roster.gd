extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1200, 1200)
	root.content_scale_size = Vector2i(1200, 1200)
	var background := ColorRect.new()
	background.size = Vector2(1200, 1200)
	background.color = Color("101c30")
	root.add_child(background)
	var bridge = load("res://scripts/visuals/art_bridge.gd").new(null)
	var catalog = load("res://scripts/data/catalog.gd")
	var states := ["idle", "run", "windup", "attack", "hurt", "death"]
	for row in range(5):
		var spec: Resource = catalog.ENEMIES[5 + row]
		var label := Label.new()
		label.text = "LEVEL %d  /  %s" % [row + 1, spec.title_en]
		label.position = Vector2(18, row * 240 + 8)
		root.add_child(label)
		for col in range(6):
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = bridge.boss_frames(spec.id)
			sprite.position = Vector2(100 + col * 200, 130 + row * 240)
			sprite.scale = Vector2.ONE * (180.0 / sprite.sprite_frames.get_frame_texture("idle", 0).get_width())
			root.add_child(sprite)
			sprite.animation = states[col]
			sprite.frame = 1 if col == 5 else 0
			var caption := Label.new()
			caption.text = states[col]
			caption.position = Vector2(65 + col * 200, 215 + row * 240)
			root.add_child(caption)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/boss_roster_preview.png")
	quit()
