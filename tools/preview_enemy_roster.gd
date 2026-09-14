extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1050, 1150)
	root.content_scale_size = Vector2i(1050, 1150)
	var background := ColorRect.new()
	background.color = Color("101c30")
	background.size = Vector2(1050, 1150)
	root.add_child(background)
	var bridge = load("res://scripts/visuals/art_bridge.gd").new(null)
	for row in range(5):
		for col in range(3):
			var family := row * 3 + col
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = bridge.roster_frames(family)
			sprite.position = Vector2(175 + col * 350, 100 + row * 225)
			sprite.scale = Vector2.ONE * 0.9
			root.add_child(sprite)
			sprite.play("run")
			var label := Label.new()
			label.text = "LEVEL %d  /  %s" % [row + 1, load("res://scripts/data/catalog.gd").ENEMIES[10 + family].title_en]
			label.position = Vector2(22 + col * 350, 185 + row * 225)
			root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/enemy_roster_preview.png")
	quit()
