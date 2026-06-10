extends Node
## Global select-and-place controller for point-and-click cooking gameplay.

signal selection_changed(source: Node)
signal selection_cleared()
signal placement_succeeded(source: Node, destination: Node)
signal placement_failed(source: Node, destination: Node, reason: String)
signal input_lock_changed(locked: bool)


var selected_source: Node = null
var input_locked: bool = false


func set_input_locked(locked: bool) -> void:
	if input_locked == locked:
		return
	input_locked = locked
	if locked:
		clear_selection()
	input_lock_changed.emit(locked)


func is_input_locked() -> bool:
	return input_locked


func has_selection() -> bool:
	return selected_source != null


func get_item_data() -> Dictionary:
	if selected_source == null:
		return {}
	return selected_source.get_item_data()


func get_selected_state() -> String:
	return get_item_data().get("item_state", "")


func select(source: Node) -> void:
	if input_locked:
		return
	if source == null or not source.has_method("get_item_data"):
		return
	if source is SelectableSource and source.has_method("is_occupied"):
		if not source.is_occupied():
			return
	if source is ServingPlate:
		var plate := source as ServingPlate
		if plate.is_respawning() or not plate.has_food():
			return

	if selected_source == source:
		clear_selection()
		return

	selected_source = source
	selection_changed.emit(source)


func clear_selection() -> void:
	if selected_source == null:
		return
	selected_source = null
	selection_cleared.emit()


func try_place(destination: Node) -> bool:
	if input_locked:
		placement_failed.emit(selected_source, destination, "input_locked")
		return false
	if selected_source == null:
		placement_failed.emit(null, destination, "nothing_selected")
		return false
	if destination == null or not destination.has_method("can_accept"):
		placement_failed.emit(selected_source, destination, "invalid_destination")
		return false

	var item_data: Dictionary = selected_source.get_item_data()
	if not destination.can_accept(item_data):
		placement_failed.emit(selected_source, destination, "invalid_item_for_slot")


		return false

	var source: Node = selected_source
	clear_selection()
	destination.receive_item(source, item_data)
	placement_succeeded.emit(source, destination)
	return true
