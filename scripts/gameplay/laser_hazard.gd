extends Node
## Periodic laser sweep — locks player input while the beam crosses the screen.

signal laser_started
signal laser_finished

@export var beam: ColorRect
@export var warning_label: Label
@export var interval_min: float = 14.0
@export var interval_max: float = 22.0
@export var warning_seconds: float = 1.1
@export var sweep_seconds: float = 1.35
@export var beam_width: float = 72.0

var _running: bool = false


func _ready() -> void:
	if beam:
		beam.visible = false
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if warning_label:
		warning_label.visible = false
		warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_loop")


func _loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(interval_min, interval_max)).timeout
		await _run_laser()


func _run_laser() -> void:
	if _running or beam == null:
		return
	_running = true
	laser_started.emit()

	if warning_label:
		warning_label.visible = true

	#GameManager.set_input_locked(true)
	%Interactables.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(warning_seconds).timeout

	var viewport_h := KitchenLayout.VIEWPORT_SIZE.y
	beam.size = Vector2(beam_width, viewport_h + 40.0)
	beam.position = Vector2(-beam_width - 20.0, -20.0)
	beam.visible = true
	beam.modulate = Color(1.0, 0.25, 0.35, 0.82)

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
	if warning_label:
		warning_label.visible = false

	#GameManager.set_input_locked(false)
	%Interactables.process_mode = Node.PROCESS_MODE_INHERIT
	_running = false
	laser_finished.emit()
