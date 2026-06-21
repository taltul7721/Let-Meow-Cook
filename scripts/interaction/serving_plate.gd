class_name ServingPlate
extends PlaceDestination

@export var plate_visual: TextureRect
@export var food_visual: TextureRect
@export var plate_display_size: Vector2 = KitchenLayout.PLATE_DISPLAY_SIZE
@export var plate_food_size: Vector2 = KitchenLayout.PLATE_FOOD_SIZE
@export var plate_food_y_offset: float = KitchenLayout.PLATE_FOOD_Y_OFFSET
@export var plate_respawn_delay: float = 1.5
@export var sfx : AudioStreamPlayer2D

const HIGHLIGHT_SELECT := Color(1.4, 1.35, 0.7, 1.0)

var _rest_position: Vector2 = Vector2.ZERO
var _respawning: bool = false
var _respawn_generation: int = 0
var _food_outline: ShaderMaterial
var _plate_outline: ShaderMaterial


func _ready() -> void:
	super._ready()
	if accepted_item_ids.is_empty():
		accepted_item_ids = ["fish"]
	if accepted_states.is_empty():
		accepted_states = ["cut", "cooked"]
	copy_source_texture = false
	texture_normal = null
	modulate = Color(1, 1, 1, 0.01)
	_rest_position = position
	if plate_visual == null and has_node("../PlateVisual"):
		plate_visual = get_node("../PlateVisual") as TextureRect
	_clear_food_visual()
	_restore_plate_visual()


func bind_visuals(visual: TextureRect, food: TextureRect) -> void:
	plate_visual = visual
	food_visual = food
	if food_visual:
		food_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_outlines()


func _ensure_outlines() -> void:
	if plate_visual and _plate_outline == null:
		_plate_outline = ItemOutline.apply_to(plate_visual, ItemOutline.DEFAULT_COLOR, 2.0)
	if food_visual and _food_outline == null:
		_food_outline = ItemOutline.apply_to(food_visual, ItemOutline.DEFAULT_COLOR, 2.5)


func setup_plate_art(tex: Texture2D) -> void:
	if plate_visual == null or tex == null:
		return
	ItemDisplay.apply_sized_rect(plate_visual, tex, plate_display_size)
	plate_visual.visible = true
	plate_visual.modulate = Color.WHITE
	plate_visual.position = position
	Juice.center_pivot(plate_visual)
	plate_visual.scale = Vector2.ZERO
	Juice.elastic_pop_in(plate_visual, KitchenLayout.JUICE_SPRING_DURATION)


func is_respawning() -> bool:
	return _respawning


func can_accept(item_data: Dictionary) -> bool:
	if _occupied or _respawning:
		return false
	if GameManager.selected_source is ServingPlate:
		return false
	if not FishAssets.is_edible(item_data.get("item_state", "")):
		return false
	return super.can_accept(item_data)


func receive_item(source: Node, item_data: Dictionary) -> void:
	_stored_item_id = item_data.get("item_id", "")
	_stored_item_state = item_data.get("item_state", "")
	_occupied = true

	var tex = (source as SelectableSource).texture_normal

	_show_food_on_plate(tex)


func get_item_data() -> Dictionary:
	return {"item_id": _stored_item_id, "item_state": _stored_item_state}


func has_food() -> bool:
	return _occupied and _stored_item_id != "" and not _respawning


func clear_item() -> void:
	_occupied = false
	_stored_item_id = ""
	_stored_item_state = ""
	_clear_food_visual()
	set_highlighted(false)


func reset_after_trash() -> void:
	_cancel_respawn()
	clear_item()
	_restore_plate_visual()


func consume_for_serve() -> void:
	if _respawning or not _occupied:
		return
	_respawn_generation += 1
	var generation := _respawn_generation
	_run_respawn_sequence(generation)


func _cancel_respawn() -> void:
	_respawn_generation += 1
	_respawning = false
	disabled = false


func _run_respawn_sequence(generation: int) -> void:
	if GameManager.selected_source == self:
		GameManager.clear_selection()
	_respawning = true
	disabled = true
	var prior_mode := process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

	await _fade_out_plate()
	if not _respawn_still_valid(generation):
		_finish_respawn(prior_mode)
		return

	await _pause_safe_delay(plate_respawn_delay)
	if not _respawn_still_valid(generation):
		_finish_respawn(prior_mode)
		return

	clear_item()
	await _respawn_plate_animation()
	if not _respawn_still_valid(generation):
		_finish_respawn(prior_mode)
		return

	_finish_respawn(prior_mode)


func _respawn_still_valid(generation: int) -> bool:
	return generation == _respawn_generation and is_inside_tree()


func _finish_respawn(prior_mode: Node.ProcessMode) -> void:
	_respawning = false
	disabled = false
	process_mode = prior_mode
	_restore_plate_visual()


func _restore_plate_visual() -> void:
	if plate_visual:
		plate_visual.visible = true
		plate_visual.modulate = Color.WHITE
		plate_visual.scale = Vector2.ONE
	if food_visual:
		food_visual.modulate = Color.WHITE


func _pause_safe_delay(seconds: float) -> void:
	var timer := get_tree().create_timer(seconds, true)
	await timer.timeout


func set_highlighted(active: bool) -> void:
	if _respawning:
		return
	if _occupied:
		_ensure_outlines()
		ItemOutline.set_enabled(_food_outline, active)
		ItemOutline.set_enabled(_plate_outline, active)
		return
	super.set_highlighted(active)


func _on_selection_changed(_source: Node) -> void:
	if _occupied:
		set_highlighted(GameManager.selected_source == self)


func _on_selection_cleared() -> void:
	if _occupied:
		set_highlighted(false)


func _on_pressed() -> void:
	if GameManager.is_input_locked():
		return
	if _respawning:
		return
	if not _occupied:
		GameManager.try_place(self)
		return
	if has_food():
		GameManager.select(self)
	sfx.play()


func _show_food_on_plate(tex: Texture2D) -> void:
	if food_visual == null or tex == null:
		return
	ItemDisplay.apply_sized_rect(food_visual, tex, plate_food_size)
	food_visual.visible = true
	food_visual.modulate = Color.WHITE
	if plate_visual:
		ItemDisplay.center_on_control(food_visual, plate_visual)
		food_visual.position.y += plate_food_y_offset
	else:
		food_visual.position = position + (size - food_visual.size) * 0.5
		food_visual.position.y += plate_food_y_offset
	Juice.elastic_pop_in(food_visual, KitchenLayout.JUICE_SPRING_DURATION)


func _clear_food_visual() -> void:
	if food_visual:
		ItemDisplay.clear_rect(food_visual)


func _fade_out_plate() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TweenPauseMode.TWEEN_PAUSE_PROCESS)
	if plate_visual:
		tween.tween_property(plate_visual, "modulate:a", 0.0, 0.32)
	if food_visual and food_visual.visible:
		tween.tween_property(food_visual, "modulate:a", 0.0, 0.32)
	await tween.finished


func _respawn_plate_animation() -> void:
	if plate_visual:
		plate_visual.modulate = Color.WHITE
		plate_visual.visible = true
		Juice.elastic_pop_in(plate_visual, KitchenLayout.JUICE_SPRING_DURATION)
	if food_visual:
		food_visual.modulate = Color.WHITE
	await _pause_safe_delay(KitchenLayout.JUICE_SPRING_DURATION)
