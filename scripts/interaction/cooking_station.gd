class_name CookingStation
extends PlaceDestination

@export var cook_duration: float = 2.0
@export var output_state: String = "cooked"
@export var output_texture: Texture2D
@export var cooking_display_texture: Texture2D
@export var processing_display_size: Vector2 = KitchenLayout.BOARD_PROCESSING_SIZE
@export var pickup_display_size: Vector2 = KitchenLayout.STATION_PICKUP_SIZE
@export var pickup_source: SelectableSource
@export var progress_bar: TextureProgressBar
@export var processing_visual: TextureRect
@export var chop_particles: CPUParticles2D
@export var sizzle_particles: CPUParticles2D
@export var use_chop_poof: bool = false

var _cooking: bool = false
var _cook_time_left: float = 0.0
var _fx_parent: Node = null
var _poof_played_midway: bool = false


func _ready() -> void:
	super._ready()
	_cooking = false
	_cook_time_left = 0.0
	_occupied = false
	_stored_item_id = ""
	_stored_item_state = ""
	_poof_played_midway = false
	texture_normal = null
	modulate = Color(1, 1, 1, 0.01)

	if processing_visual:
		processing_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		processing_visual.z_index = 15
		_clear_processing_visual()
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0.0
		progress_bar.z_index = 25
		ProgressBarStyle.fit(progress_bar, ProgressBarStyle.WIDTH_STATION)
	if chop_particles:
		chop_particles.emitting = false
	if sizzle_particles:
		sizzle_particles.emitting = false

	call_deferred("_setup_pickup_overlay")
	GameManager.placement_succeeded.connect(_on_placement_succeeded)


func set_fx_parent(node: Node) -> void:
	_fx_parent = node


func _setup_pickup_overlay() -> void:
	if pickup_source == null:
		return
	pickup_source.prepare_empty_pickup()
	pickup_source.z_index = 16


func _process(delta: float) -> void:
	if not _cooking:
		return
	_cook_time_left = maxf(_cook_time_left - delta, 0.0)
	_update_progress()
	if use_chop_poof and not _poof_played_midway and _cook_time_left <= cook_duration * 0.45:
		_poof_played_midway = true
		_burst_chop_particles()
		_play_chop_poof()
	if _cook_time_left <= 0.0:
		_finish_cooking()


func can_accept(item_data: Dictionary) -> bool:
	if _cooking:
		return false
	if pickup_source and pickup_source.is_occupied():
		return false
	return super.can_accept(item_data)


func is_cooking() -> bool:
	return _cooking


func set_highlighted(_active: bool) -> void:
	pass


func _update_destination_hint() -> void:
	pass


func receive_item(source: Node, item_data: Dictionary) -> void:
	_stored_item_id = item_data.get("item_id", "")
	_stored_item_state = item_data.get("item_state", "")
	_occupied = true
	modulate = Color(1, 1, 1, 0.01)
	_clear_placement_source(source)
	_start_cooking(item_data)


func clear_slot() -> void:
	_stop_sizzle()
	_cooking = false
	_cook_time_left = 0.0
	_occupied = false
	_stored_item_id = ""
	_stored_item_state = ""
	_poof_played_midway = false
	modulate = Color(1, 1, 1, 0.01)
	_clear_processing_visual()
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0.0


func _start_cooking(_item_data: Dictionary) -> void:
	_cooking = true
	_cook_time_left = cook_duration
	_poof_played_midway = false
	if pickup_source:
		pickup_source.visible = false
	_show_processing_visual()
	_update_progress()
	_burst_chop_particles()
	if use_chop_poof:
		_play_chop_poof()
	_start_sizzle()
	if cook_duration <= 0.0:
		_finish_cooking()


func _finish_cooking() -> void:
	_cooking = false
	_cook_time_left = 0.0
	_stored_item_state = output_state
	_stop_sizzle()
	_clear_processing_visual()
	_update_progress()
	_poof_played_midway = false

	if pickup_source:
		var tex := output_texture if output_texture else cooking_display_texture
		pickup_source.refill_from_station(_stored_item_id, output_state, tex, pickup_display_size)
		ItemDisplay.center_on_control(pickup_source, self)
		Juice.elastic_pop_in(pickup_source, KitchenLayout.JUICE_SPRING_DURATION)
	else:
		clear_slot()


func _show_processing_visual() -> void:
	if processing_visual == null:
		return
	var tex := cooking_display_texture
	if tex == null:
		_clear_processing_visual()
		return
	ItemDisplay.apply_sized_rect(processing_visual, tex, processing_display_size)
	ItemDisplay.center_on_control(processing_visual, self)
	processing_visual.modulate = Color.WHITE
	processing_visual.visible = true
	Juice.elastic_pop_in(processing_visual, KitchenLayout.JUICE_SPRING_DURATION)
	_layout_progress_bar()


func _layout_progress_bar() -> void:
	if progress_bar == null or processing_visual == null:
		return
	ProgressBarStyle.fit(progress_bar, ProgressBarStyle.WIDTH_STATION)
	ProgressBarStyle.place_above(progress_bar, processing_visual, 8.0)


func _clear_processing_visual() -> void:
	if processing_visual:
		ItemDisplay.clear_rect(processing_visual)


func _sync_particle_position(particles: CPUParticles2D) -> void:
	if particles == null:
		return
	particles.position = position + size * 0.5


func _burst_chop_particles() -> void:
	if chop_particles == null:
		return
	_sync_particle_position(chop_particles)
	chop_particles.restart()
	chop_particles.emitting = true


func _start_sizzle() -> void:
	if sizzle_particles == null:
		return
	_sync_particle_position(sizzle_particles)
	sizzle_particles.emitting = true


func _stop_sizzle() -> void:
	if sizzle_particles:
		sizzle_particles.emitting = false


func _fx_anchor_global() -> Vector2:
	if processing_visual and processing_visual.visible:
		return processing_visual.global_position + processing_visual.size * 0.5
	return global_position + size * 0.5


func _play_chop_poof() -> void:
	var parent := _fx_parent if _fx_parent else get_parent()
	KitchenFx.play_chop_poof(parent, _fx_anchor_global())


func _update_progress() -> void:
	if progress_bar == null:
		return
	progress_bar.visible = _cooking
	if not _cooking:
		return
	var target := 1.0
	if cook_duration > 0.0:
		target = 1.0 - (_cook_time_left / cook_duration)
	Juice.tween_progress(progress_bar, target, 0.12)


func _on_placement_succeeded(source: Node, _destination: Node) -> void:
	if pickup_source == null or source != pickup_source:
		return
	clear_slot()
