class_name KitchenFx
extends RefCounted


static func play_chop_poof(parent: Node, world_pos: Vector2) -> void:
	if parent == null:
		return
	var host := Node2D.new()
	host.name = "ChopPoof"
	host.z_index = 28
	host.global_position = world_pos
	parent.add_child(host)

	var colors := [
		Color(0.95, 0.9, 0.75, 0.9),
		Color(0.85, 0.8, 0.65, 0.75),
		Color(1.0, 0.95, 0.85, 0.65),
	]
	for i in range(5):
		var puff := _make_puff_sprite(colors[i % colors.size()], 18.0 + float(i) * 6.0)
		puff.position = Vector2(randf_range(-22, 22), randf_range(-18, 10))
		host.add_child(puff)
		_animate_puff(puff, 0.32 + float(i) * 0.04)

	var timer: SceneTreeTimer = host.get_tree().create_timer(0.55)
	timer.timeout.connect(host.queue_free)


static func start_grill_smoke(parent: Node, world_pos: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "GrillSmoke"
	particles.z_index = 26
	particles.global_position = world_pos
	particles.amount = 18
	particles.lifetime = 1.4
	particles.preprocess = 0.2
	particles.explosiveness = 0.0
	particles.randomness = 0.35
	particles.emitting = true
	particles.direction = Vector2(0, -1)
	particles.spread = 28.0
	particles.gravity = Vector2(0, -28)
	particles.initial_velocity_min = 12.0
	particles.initial_velocity_max = 38.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.85
	particles.color = Color(0.72, 0.72, 0.78, 0.45)
	parent.add_child(particles)
	return particles


static func play_serve_sparkle(parent: Node, world_pos: Vector2) -> void:
	if parent == null:
		return
	var host := Node2D.new()
	host.name = "ServeSparkle"
	host.z_index = 32
	host.global_position = world_pos
	parent.add_child(host)
	var colors := [Color(1, 0.95, 0.4), Color(0.5, 1, 0.65), Color(1, 0.8, 0.5)]
	for i in range(6):
		var puff := _make_puff_sprite(colors[i % colors.size()], 10.0 + float(i) * 3.0)
		puff.position = Vector2(randf_range(-30, 30), randf_range(-24, 8))
		host.add_child(puff)
		_animate_puff(puff, 0.28 + float(i) * 0.03)
	var timer: SceneTreeTimer = host.get_tree().create_timer(0.5)
	timer.timeout.connect(host.queue_free)


static func play_trash_dump(parent: Node, world_pos: Vector2) -> void:
	if parent == null:
		return
	var host := Node2D.new()
	host.name = "TrashDump"
	host.z_index = 28
	host.global_position = world_pos
	parent.add_child(host)
	var colors := [
		Color(0.55, 0.58, 0.62, 0.85),
		Color(0.42, 0.45, 0.5, 0.75),
		Color(0.68, 0.7, 0.74, 0.65),
	]
	for i in range(5):
		var puff := _make_puff_sprite(colors[i % colors.size()], 14.0 + float(i) * 4.0)
		puff.position = Vector2(randf_range(-16, 16), randf_range(-8, 4))
		host.add_child(puff)
		_animate_falling_puff(puff, 0.34 + float(i) * 0.04)
	var timer: SceneTreeTimer = host.get_tree().create_timer(0.6)
	timer.timeout.connect(host.queue_free)


static func stop_grill_smoke(particles: CPUParticles2D) -> void:
	if particles == null or not is_instance_valid(particles):
		return
	particles.emitting = false
	var timer: SceneTreeTimer = particles.get_tree().create_timer(1.6)
	timer.timeout.connect(particles.queue_free)


static func configure_burn_flames(particles: CPUParticles2D, layer: int = 0) -> void:
	if particles == null:
		return
	var width := 14.0 + float(layer) * 6.0
	particles.texture = make_soft_particle_texture(7)
	particles.amount = 9 + layer * 3
	particles.lifetime = 0.38 + float(layer) * 0.04
	particles.preprocess = 0.12
	particles.explosiveness = 0.05
	particles.randomness = 0.35
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(width, 5.0)
	particles.direction = Vector2(0, -1)
	particles.spread = 16.0 + float(layer) * 4.0
	particles.gravity = Vector2(0, -22)
	particles.initial_velocity_min = 6.0
	particles.initial_velocity_max = 16.0 + float(layer) * 2.0
	particles.scale_amount_min = 0.18
	particles.scale_amount_max = 0.42 + float(layer) * 0.05
	particles.color = Color(1, 0.58 + float(layer) * 0.04, 0.1, 0.8)
	particles.color_ramp = null


static func make_soft_particle_texture(radius: float) -> ImageTexture:
	var size := int(radius * 2.0)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(radius, radius)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center) / radius
			if d <= 1.0:
				var a := pow(1.0 - d, 1.25)
				img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


static func _make_puff_sprite(color: Color, radius: float) -> Sprite2D:
	var img := Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(radius, radius)
	for y in img.get_height():
		for x in img.get_width():
			var d := Vector2(x, y).distance_to(center) / radius
			if d <= 1.0:
				var a := (1.0 - d) * (1.0 - d)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(0.3, 0.3)
	spr.modulate = color
	return spr


static func _animate_puff(puff: Sprite2D, duration: float) -> void:
	var tween := puff.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(puff, "scale", Vector2(1.35, 1.35), duration)
	tween.tween_property(puff, "modulate:a", 0.0, duration)


static func _animate_falling_puff(puff: Sprite2D, duration: float) -> void:
	var tween := puff.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(puff, "position:y", puff.position.y + 28.0, duration)
	tween.tween_property(puff, "scale", Vector2(0.9, 0.9), duration)
	tween.tween_property(puff, "modulate:a", 0.0, duration)
