class_name PlaceDestination
extends TextureButton
## Invisible click/drop zone over background art. Never assign artwork to this node.

@export var accepted_item_ids: Array[String] = []
@export var accepted_states: Array[String] = []
@export var invalid_flash_color: Color = Color(1.6, 0.45, 0.45, 1.0)
@export var copy_source_texture: bool = false

var _occupied: bool = false
var _stored_item_id: String = ""
var _stored_item_state: String = ""
var _highlight_node: CanvasItem = null


func _ready() -> void:
	if has_node("Highlight") and get_node("Highlight") is CanvasItem:
		_highlight_node = get_node("Highlight") as CanvasItem
		_highlight_node.visible = false
		_highlight_node.modulate = Color(1, 1, 1, 0)
	GameManager.selection_changed.connect(_on_selection_changed)
	GameManager.selection_cleared.connect(_on_selection_cleared)
	pressed.connect(_on_pressed)
	_update_destination_hint()


func is_station_occupied() -> bool:
	return _occupied


func can_accept(item_data: Dictionary) -> bool:
	if _occupied:
		return false
	var id: String = item_data.get("item_id", "")
	var state: String = item_data.get("item_state", "")
	if not accepted_item_ids.is_empty() and id not in accepted_item_ids:
		return false
	if not accepted_states.is_empty() and state not in accepted_states:
		return false
	return true


#func receive_item(source: Node, item_data: Dictionary) -> void:
	#_stored_item_id = item_data.get("item_id", "")
	#_stored_item_state = item_data.get("item_state", "")
	#_occupied = true
	#set_highlighted(false)
	#if copy_source_texture and source is SelectableSource:
		#var src := source as SelectableSource
		#if src.texture_normal:
			#texture_normal = src.texture_normal
	#_clear_placement_source(source)


func _clear_placement_source(source: Node) -> void:
	if source != null and source.has_method("clear_item"):
		source.clear_item()


func flash_invalid() -> void:
	if _highlight_node:
		var old := _highlight_node.modulate
		_highlight_node.visible = true
		var tween_h := create_tween()
		tween_h.tween_property(_highlight_node, "modulate", invalid_flash_color, 0.08)
		tween_h.tween_property(_highlight_node, "modulate", old, 0.12)
	var tween := create_tween()
	tween.tween_property(self, "modulate", invalid_flash_color, 0.08)
	await tween.finished
	_update_destination_hint()


func set_highlighted(active: bool) -> void:
	if _highlight_node == null:
		return
	if _occupied:
		active = false
	_highlight_node.visible = active
	if active:
		_highlight_node.modulate = Color(1.0, 1.0, 1.0, 0.9)
		var pulse := create_tween()
		pulse.set_loops()
		pulse.tween_property(_highlight_node, "modulate:a", 0.5, 0.5)
		pulse.tween_property(_highlight_node, "modulate:a", 0.95, 0.5)
	else:
		_highlight_node.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _on_pressed() -> void:
	if GameManager.is_input_locked():
		return
	GameManager.try_place(self)


func _on_selection_changed(_source: Node) -> void:
	_update_destination_hint()


func _on_selection_cleared() -> void:
	set_highlighted(false)


func _update_destination_hint() -> void:
	if _occupied or not GameManager.has_selection():
		set_highlighted(false)
		return
	set_highlighted(can_accept(GameManager.get_item_data()))
