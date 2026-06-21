class_name CookingStation
extends PlaceDestination

const STATE_OVERCOOKED := "overcooked"
const BURNT_MODULATE := Color(0.14, 0.12, 0.12, 1.0)

@export var cook_duration: float = 2.0
@export var output_state: String = "cooked"
@export var enable_overcook: bool = false
@export var overcook_delay: float = 4.0
@export var cooking_display_texture: AtlasTexture
@export var processing_display_size: Vector2 = KitchenLayout.BOARD_PROCESSING_SIZE
@export var pickup_display_size: Vector2 = KitchenLayout.STATION_PICKUP_SIZE
@export var pickup_destination: SelectableSource
@export var progress_bar: TextureProgressBar
@export var processing_visual: TextureRect
@export var chop_particles: CPUParticles2D
@export var sizzle_particles: CPUParticles2D
@export var burn_particles: CPUParticles2D
@export var burn_particles_extra: Array[CPUParticles2D] = []
@export var use_chop_poof: bool = false
@export var sfx : AudioStreamPlayer2D

const BURN_PARTICLE_OFFSETS := [
	Vector2.ZERO,
	Vector2(-24, 5),
	Vector2(24, 3),
	Vector2(-10, -7),
	Vector2(12, -5),
]

var _cooking: bool = false
var _cook_time_left: float = 0.0
var _overcook_time_left: float = -1.0
var _fx_parent: Node = null
var _poof_played_midway: bool = false


func _ready() -> void:
	super._ready()
	if accepted_item_ids.is_empty():
		accepted_item_ids = ["fish"]
	if accepted_states.is_empty():
		accepted_states = ["raw"]
	_cooking = false
	_cook_time_left = 0.0
	_overcook_time_left = -1.0
	_occupied = false
	_stored_item_id = ""
	_stored_item_state = ""
	_poof_played_midway = false

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
	if burn_particles:
		_setup_burn_layers()

	call_deferred("_setup_pickup_overlay")
	GameManager.placement_succeeded.connect(_on_placement_succeeded)


func set_fx_parent(node: Node) -> void:
	_fx_parent = node


func _setup_pickup_overlay() -> void:
	if pickup_destination == null:
		return
	pickup_destination.z_index = 16
	pickup_destination.occupied = false
	pickup_destination.visible = false
	pickup_destination.modulate = Color.WHITE


func _process(delta: float) -> void:
	if _cooking:
		_cook_time_left = maxf(_cook_time_left - delta, 0.0)
		_update_progress()
		if use_chop_poof and not _poof_played_midway and _cook_time_left <= cook_duration * 0.45:
			_poof_played_midway = true
			_burst_chop_particles()
			_play_chop_poof()
		if _cook_time_left <= 0.0:
			_finish_cooking()
		return

	if _overcook_time_left > 0.0 and _pickup_waiting_to_burn():
		_overcook_time_left = maxf(_overcook_time_left - delta, 0.0)
		_sync_particle_position(sizzle_particles)
		_update_overcook_progress()
		if _overcook_time_left <= 0.0:
			_overcook_pickup()
		return

	if _is_burning():
		_sync_particle_position(sizzle_particles)
		_sync_burn_particles()


func can_accept(item_data: Dictionary) -> bool:
	if _cooking:
		return false
	if pickup_destination and pickup_destination.visible and pickup_destination.is_occupied():
		return false
	return _is_raw_fish(item_data)


func _is_raw_fish(item_data: Dictionary) -> bool:
	return item_data.get("item_id", "") == "fish" and item_data.get("item_state", "") == "raw"


func is_cooking() -> bool:
	return _cooking


func set_highlighted(_active: bool) -> void:
	pass


func _update_destination_hint() -> void:
	pass


func receive_item(source: Node, item_data: Dictionary) -> void:
	_stored_item_id = item_data.get("item_id", "")
	_stored_item_state = item_data.get("item_state", "")
	cooking_display_texture.region.position = owner.atlas_coordinates[_stored_item_id + " " + _stored_item_state]
	_occupied = true
	_start_cooking(item_data)


func clear_slot() -> void:
	_stop_chop_smoke()
	_stop_sizzle()
	_stop_burn()
	_cancel_overcook_timer()
	_cooking = false
	_cook_time_left = 0.0
	_occupied = false
	_stored_item_id = ""
	_stored_item_state = ""
	_poof_played_midway = false
	modulate = Color(1, 1, 1, 0.00)
	if pickup_destination:
		pickup_destination.visible = false
		pickup_destination.occupied = false
		pickup_destination.modulate = Color.WHITE
		if pickup_destination.item_state == STATE_OVERCOOKED:
			pickup_destination.item_state = output_state
	_clear_processing_visual()
	_hide_progress_bar()


func _start_cooking(_item_data: Dictionary) -> void:
	_cancel_overcook_timer()
	_cooking = true
	_cook_time_left = cook_duration
	_poof_played_midway = false
	if pickup_destination:
		pickup_destination.visible = false
	_show_processing_visual()
	_update_progress()
	_start_chop_smoke()
	_burst_chop_particles()
	if use_chop_poof:
		_play_chop_poof()
	_start_sizzle()
	if cook_duration <= 0.0:
		_finish_cooking()


func _finish_cooking() -> void:
	_cooking = false
	_cook_time_left = 0.0
	_occupied = false
	_stored_item_state = output_state
	_stop_chop_smoke()
	_clear_processing_visual()
	_poof_played_midway = false

	if pickup_destination:
		pickup_destination.item_id = _stored_item_id
		pickup_destination.item_state = output_state
		pickup_destination.modulate = Color.WHITE
		pickup_destination.visible = true
		pickup_destination.occupied = true
		_apply_pickup_texture()
		ItemDisplay.center_on_control(pickup_destination, self)
		Juice.elastic_pop_in(pickup_destination, KitchenLayout.JUICE_SPRING_DURATION)
		if enable_overcook and output_state == "cooked":
			_overcook_time_left = overcook_delay
			_sync_particle_position(sizzle_particles)
			_layout_overcook_progress_bar()
			_update_overcook_progress()
		else:
			_stop_sizzle()
			_hide_progress_bar()
	else:
		_stop_sizzle()
		clear_slot()


func _pickup_waiting_to_burn() -> bool:
	if pickup_destination == null or not pickup_destination.visible:
		return false
	if not pickup_destination.is_occupied():
		return false
	return pickup_destination.item_state == output_state


func _overcook_pickup() -> void:
	_cancel_overcook_timer()
	_hide_progress_bar()
	if pickup_destination == null or not pickup_destination.visible:
		return
	pickup_destination.item_state = STATE_OVERCOOKED
	pickup_destination.modulate = BURNT_MODULATE
	_apply_pickup_texture()
	_start_burn()


func _apply_pickup_texture() -> void:
	if pickup_destination == null or pickup_destination.texture_normal == null:
		return
	var atlas_key := _pickup_atlas_key(pickup_destination.item_state)
	if owner == null or not owner.atlas_coordinates.has(atlas_key):
		return
	(pickup_destination.texture_normal as AtlasTexture).region.position = owner.atlas_coordinates[atlas_key]


func _pickup_atlas_key(state: String) -> String:
	if state == STATE_OVERCOOKED:
		return "%s %s" % [_stored_item_id if _stored_item_id != "" else "fish", output_state]
	return "%s %s" % [_stored_item_id if _stored_item_id != "" else "fish", state]


func _cancel_overcook_timer() -> void:
	_overcook_time_left = -1.0
	if not _cooking:
		_hide_progress_bar()


func _show_processing_visual() -> void:
	ItemDisplay.apply_sized_rect(processing_visual, cooking_display_texture, processing_display_size)
	ItemDisplay.center_on_control(processing_visual, self)
	processing_visual.visible = true
	Juice.elastic_pop_in(processing_visual, KitchenLayout.JUICE_SPRING_DURATION)
	_layout_progress_bar()


func _layout_progress_bar() -> void:
	if progress_bar == null or processing_visual == null:
		return
	ProgressBarStyle.fit(progress_bar, ProgressBarStyle.WIDTH_STATION)
	ProgressBarStyle.place_above(progress_bar, processing_visual, 8.0)


func _layout_overcook_progress_bar() -> void:
	if progress_bar == null or pickup_destination == null:
		return
	ProgressBarStyle.fit(progress_bar, ProgressBarStyle.WIDTH_STATION)
	ProgressBarStyle.place_above(progress_bar, pickup_destination, 8.0)


func _clear_processing_visual() -> void:
	processing_visual.visible = false


func _sync_particle_position(particles: CPUParticles2D) -> void:
	if particles == null:
		return
	if pickup_destination and pickup_destination.visible:
		particles.position = pickup_destination.position + pickup_destination.size * 0.5
	else:
		particles.position = position + size * 0.5


func _burst_chop_particles() -> void:
	if chop_particles == null:
		return
	_sync_particle_position(chop_particles)
	chop_particles.restart()


func _start_chop_smoke() -> void:
	if chop_particles == null:
		return
	_sync_particle_position(chop_particles)
	chop_particles.emitting = true


func _stop_chop_smoke() -> void:
	if chop_particles:
		chop_particles.emitting = false


func _start_sizzle() -> void:
	if sizzle_particles:
		_sync_particle_position(sizzle_particles)
		sizzle_particles.emitting = true
	_start_grill_audio()


func _stop_sizzle() -> void:
	if sizzle_particles:
		sizzle_particles.emitting = false
	_stop_grill_audio()


func _start_grill_audio() -> void:
	if sfx == null or sizzle_particles == null:
		return
	var stream := sfx.stream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	if not sfx.playing:
		sfx.play()


func _stop_grill_audio() -> void:
	if sfx == null or sizzle_particles == null:
		return
	if sfx.playing:
		sfx.stop()


func _setup_burn_layers() -> void:
	var layer := 0
	for particles in _burn_particle_nodes():
		KitchenFx.configure_burn_flames(particles, layer)
		particles.emitting = false
		layer += 1


func _burn_particle_nodes() -> Array[CPUParticles2D]:
	var nodes: Array[CPUParticles2D] = []
	if burn_particles:
		nodes.append(burn_particles)
	for particles in burn_particles_extra:
		if particles:
			nodes.append(particles)
	return nodes


func _is_burning() -> bool:
	for particles in _burn_particle_nodes():
		if particles.emitting:
			return true
	return false


func _sync_burn_particles() -> void:
	var nodes := _burn_particle_nodes()
	for i in nodes.size():
		var offset: Vector2 = BURN_PARTICLE_OFFSETS[i] if i < BURN_PARTICLE_OFFSETS.size() else Vector2.ZERO
		_sync_particle_position_offset(nodes[i], offset)


func _sync_particle_position_offset(particles: CPUParticles2D, offset: Vector2) -> void:
	if particles == null:
		return
	if pickup_destination and pickup_destination.visible:
		particles.position = pickup_destination.position + pickup_destination.size * 0.5 + offset
	else:
		particles.position = position + size * 0.5 + offset


func _start_burn() -> void:
	for particles in _burn_particle_nodes():
		particles.emitting = true
	_sync_burn_particles()
	_start_grill_audio()


func _stop_burn() -> void:
	for particles in _burn_particle_nodes():
		particles.emitting = false


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
	if _overcook_time_left > 0.0:
		return
	progress_bar.visible = _cooking
	progress_bar.modulate = Color.WHITE
	if not _cooking:
		return
	var target := 1.0
	if cook_duration > 0.0:
		target = 1.0 - (_cook_time_left / cook_duration)
	Juice.tween_progress(progress_bar, target, 0.12)


func _update_overcook_progress() -> void:
	if progress_bar == null:
		return
	if _overcook_time_left <= 0.0 or not _pickup_waiting_to_burn():
		return
	progress_bar.visible = true
	progress_bar.modulate = Color(1, 0.52, 0.22, 1)
	var target := 1.0
	if overcook_delay > 0.0:
		target = 1.0 - (_overcook_time_left / overcook_delay)
	Juice.tween_progress(progress_bar, target, 0.12)


func _hide_progress_bar() -> void:
	if progress_bar == null:
		return
	progress_bar.visible = false
	progress_bar.value = 0.0
	progress_bar.modulate = Color.WHITE


func _on_placement_succeeded(source: Node, _destination: Node) -> void:
	if _destination == self and sizzle_particles == null and sfx:
		sfx.play()
	if pickup_destination == null or source != pickup_destination:
		return
	clear_slot()
