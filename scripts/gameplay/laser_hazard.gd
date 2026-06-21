extends Node
## Periodic laser sweep — locks player input while the beam crosses the screen.

signal laser_started
signal laser_finished

@export var beam: Laser
@export var laser_sprite: LaserSweepSprite
@export var laser_sweep_sfx: AudioStreamPlayer2D
@export var warning_label: Label
@export var warning_sfx: AudioStreamPlayer2D
@export var interval_min: float = 14.0
@export var interval_max: float = 22.0
@export var start_delay: float = 15.0
@export var warning_seconds: float = 2.0
@export var sweep_seconds: float = 1.35

var _running: bool = false
var _warning_flash: ColorRect


func _ready() -> void:
	if beam:
		beam.visible = false
	if laser_sprite:
		laser_sprite.visible = false
	_setup_warning_flash()
	if warning_label:
		warning_label.visible = false
		warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func start_hazard() -> void:
	call_deferred("_begin_after_delay")


func _begin_after_delay() -> void:
	await get_tree().create_timer(maxf(start_delay, 0.0)).timeout
	if is_inside_tree():
		_loop()


func _fx_layer() -> Node:
	if laser_sprite:
		return laser_sprite.get_parent()
	return null


func _setup_warning_flash() -> void:
	var layer := _fx_layer()
	if layer == null:
		return
	_warning_flash = ColorRect.new()
	_warning_flash.name = "LaserWarningFlash"
	_warning_flash.color = Color(1.0, 0.08, 0.12, 0.0)
	_warning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warning_flash.z_index = 20
	layer.add_child(_warning_flash)


func _uses_sprite_beam() -> bool:
	return laser_sprite != null and laser_sprite.is_configured()


func _loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(interval_min, interval_max)).timeout
		await _run_laser()


func _run_laser() -> void:
	if _running or (not _uses_sprite_beam() and beam == null):
		return
	_running = true

	await _play_warning_phase()

	if warning_label:
		warning_label.visible = false
	if _warning_flash:
		_warning_flash.color.a = 0.0

	$"../HunterVision".show()
	laser_started.emit()
	MusicManager.on_laser_started()
	%Interactables.process_mode = Node.PROCESS_MODE_DISABLED

	if _uses_sprite_beam():
		if beam:
			beam.visible = false
		await _play_sprite_beam()
	elif beam:
		await _sweep_circle_beam()

	%Interactables.process_mode = Node.PROCESS_MODE_INHERIT
	_running = false
	$"../HunterVision".hide()
	MusicManager.on_laser_finished()
	laser_finished.emit()


func _play_warning_phase() -> void:
	if warning_label:
		warning_label.text = "LASER INCOMING!"
		warning_label.visible = true
		Juice.center_pivot(warning_label)
	if warning_sfx and warning_sfx.stream:
		warning_sfx.play()

	var pulse_count := maxi(int(warning_seconds / 0.28), 1)
	for i in pulse_count:
		if warning_label:
			var label_tween := create_tween()
			label_tween.set_parallel(true)
			label_tween.tween_property(warning_label, "scale", Vector2(1.12, 1.12), 0.12)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			label_tween.tween_property(warning_label, "modulate:a", 1.0, 0.12)
		if _warning_flash:
			var flash_tween := create_tween()
			flash_tween.tween_property(_warning_flash, "color:a", 0.34, 0.08)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flash_tween.tween_property(_warning_flash, "color:a", 0.0, 0.18)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.28).timeout
		if warning_label:
			warning_label.scale = Vector2.ONE


func _play_sprite_beam() -> void:
	if laser_sweep_sfx and laser_sweep_sfx.stream:
		laser_sprite.sync_fps_to_sound(laser_sweep_sfx)
		laser_sweep_sfx.play()
	laser_sprite.play_sweep()
	await laser_sprite.sweep_finished


func _sweep_circle_beam() -> void:
	beam.position.x = beam.radius - 20.0
	beam.visible = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(
		beam,
		"position:x",
		KitchenLayout.VIEWPORT_SIZE.x + 40.0,
		sweep_seconds
	)
	await tween.finished

	beam.visible = false
