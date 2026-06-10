class_name ServingPlate
extends PlaceDestination

@export var plate_visual: TextureRect
@export var food_visual: TextureRect
@export var plate_display_size: Vector2 = KitchenLayout.PLATE_DISPLAY_SIZE
@export var plate_food_size: Vector2 = KitchenLayout.PLATE_FOOD_SIZE
@export var plate_food_y_offset: float = KitchenLayout.PLATE_FOOD_Y_OFFSET
@export var plate_respawn_delay: float = 1.5

const HIGHLIGHT_SELECT := Color(1.4, 1.35, 0.7, 1.0)

var _rest_position: Vector2 = Vector2.ZERO
var _respawning: bool = false
var _food_outline: ShaderMaterial
var _plate_outline: ShaderMaterial


func _ready() -> void:
	super._ready()
	copy_source_texture = false
	texture_normal = null
	modulate = Color(1, 1, 1, 0.01)
	_rest_position = position
	if plate_visual == null and has_node("../PlateVisual"):
		plate_visual = get_node("../PlateVisual") as TextureRect
	_clear_food_visual()
	GameManager.selection_changed.connect(_on_selection_changed)
	GameManager.selection_cleared.connect(_on_selection_cleared)


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


func consume_for_serve() -> void:
	if _respawning or not _occupied:
		return
	if GameManager.selected_source == self:
		GameManager.clear_selection()
	_respawning = true
	disabled = true
	_fade_out_plate()
	await get_tree().create_timer(plate_respawn_delay).timeout
	clear_item()
	await _respawn_plate_animation()
	_respawning = false
	disabled = false


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
	if plate_visual:
		tween.tween_property(plate_visual, "modulate:a", 0.0, 0.32)
	if food_visual and food_visual.visible:
		tween.tween_property(food_visual, "modulate:a", 0.0, 0.32)
	await tween.finished


func _respawn_plate_animation() -> void:
	if plate_visual:
		plate_visual.modulate = Color.WHITE
		Juice.elastic_pop_in(plate_visual, KitchenLayout.JUICE_SPRING_DURATION)
	if food_visual:
		food_visual.modulate = Color.WHITE
	await get_tree().create_timer(KitchenLayout.JUICE_SPRING_DURATION).timeout
