class_name SelectableSource
extends TextureButton
## Clickable food item fitted into an explicit display box.

@export var item_id: String = "fish"
@export var item_state: String = "raw"
@export var empty_texture: Texture2D
@export var highlight_color: Color = Color(1.35, 1.35, 0.75, 1.0)
@export var invalid_flash_color: Color = Color(1.6, 0.45, 0.45, 1.0)
@export var use_shader_outline: bool = true
@export var auto_refill_seconds: float = -1.0
@export var hide_when_cleared: bool = false
@export var starts_occupied: bool = true
@export var display_size: Vector2 = Vector2.ZERO
@export var spring_on_show: bool = true

var _base_modulate: Color = Color.WHITE
var _outline_material: ShaderMaterial
var _occupied: bool = true
var _filled_texture: Texture2D
var _anchor_station: Control = null


func _ready() -> void:
	_occupied = starts_occupied
	_base_modulate = modulate
	_filled_texture = texture_normal

	if not starts_occupied:
		prepare_empty_pickup()
	elif _filled_texture and display_size != Vector2.ZERO:
		ItemDisplay.apply_sized_button(self, _filled_texture, display_size)

	if use_shader_outline:
		_outline_material = ItemOutline.apply_to(self)
	pressed.connect(_on_pressed)
	GameManager.selection_cleared.connect(_on_global_selection_cleared)


func set_anchor_station(station: Control) -> void:
	_anchor_station = station


func _exit_tree() -> void:
	if GameManager.selected_source == self:
		GameManager.clear_selection()


func get_item_data() -> Dictionary:
	return {"item_id": item_id, "item_state": item_state}


func is_occupied() -> bool:
	return _occupied


func prepare_empty_pickup() -> void:
	_occupied = false
	disabled = true
	ItemDisplay.clear_button(self)


func set_highlighted(active: bool) -> void:
	if _outline_material:
		_outline_material.set_shader_parameter("enabled", active)
		return
	var target := highlight_color if active else _base_modulate
	var tween := create_tween()
	tween.tween_property(self, "modulate", target, 0.1)


func flash_invalid() -> void:
	if not _occupied:
		return
	Juice.flash_invalid(self, invalid_flash_color, _base_modulate)


func clear_item() -> void:
	_occupied = false
	ItemDisplay.clear_button(self)
	modulate = _base_modulate
	if hide_when_cleared:
		visible = false
	if auto_refill_seconds >= 0.0:
		_schedule_auto_refill()


func refill_from_station(id: String, state: String, tex: Texture2D, box_size: Vector2 = Vector2.ZERO) -> void:
	item_id = id
	item_state = state
	if tex:
		_filled_texture = tex
		var box := box_size if box_size != Vector2.ZERO else display_size
		if box != Vector2.ZERO:
			ItemDisplay.apply_sized_button(self, tex, box)
		else:
			ItemDisplay.apply_sized_button(self, tex, ItemDisplay.texture_pixel_size(tex))
		if _anchor_station:
			ItemDisplay.center_on_control(self, _anchor_station)
	_occupied = true
	disabled = false
	modulate = _base_modulate
	visible = true
	if spring_on_show:
		Juice.elastic_pop_in(self, KitchenLayout.JUICE_SPRING_DURATION)


func refill_item(state: String = "") -> void:
	_occupied = true
	if state != "":
		item_state = state
	if _filled_texture:
		if display_size != Vector2.ZERO:
			ItemDisplay.apply_sized_button(self, _filled_texture, display_size)
		else:
			ItemDisplay.apply_sized_button(self, _filled_texture, ItemDisplay.texture_pixel_size(_filled_texture))
	disabled = false
	modulate = _base_modulate
	visible = true


func _on_pressed() -> void:
	if GameManager.is_input_locked():
		return
	if not _occupied:
		return
	GameManager.select(self)


func _on_global_selection_cleared() -> void:
	if GameManager.selected_source != self:
		set_highlighted(false)


func _schedule_auto_refill() -> void:
	var timer := get_tree().create_timer(auto_refill_seconds)
	timer.timeout.connect(_on_auto_refill_timeout, CONNECT_ONE_SHOT)


func _on_auto_refill_timeout() -> void:
	if not _occupied:
		refill_item()
