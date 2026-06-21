class_name TrashBin
extends TextureButton
## Discard only the currently selected food item.

const INVALID_FLASH := Color(1.55, 0.42, 0.42, 1.0)
const READY_TINT := Color(1.08, 1.02, 0.82, 1.0)
const BURNT_HINT_TINT := Color(1.18, 0.72, 0.38, 1.0)
const BURNT_READY_TINT := Color(1.42, 0.58, 0.14, 1.0)
const BURNT_PULSE_PEAK := Color(1.65, 0.72, 0.12, 1.0)

@export var visual: Control
@export var dump_sfx: AudioStreamPlayer2D

var _ready_pulse: Tween = null


func _ready() -> void:
	texture_normal = null
	modulate = Color(1, 1, 1, 0.02)
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	GameManager.selection_changed.connect(_on_selection_changed)
	GameManager.selection_cleared.connect(_on_selection_cleared)
	if visual:
		visual.pivot_offset = visual.size * 0.5
	_update_ready_state()


func _process(_delta: float) -> void:
	if _is_burnt_selection(GameManager.selected_source):
		return
	if _kitchen_has_burnt_food():
		_apply_panel_style(true, false)
	elif visual:
		_apply_panel_style(false, false)


func _on_hover_changed(hovering: bool) -> void:
	if visual == null:
		return
	if hovering and _can_discard(GameManager.selected_source):
		if _is_burnt_selection(GameManager.selected_source):
			visual.modulate = BURNT_PULSE_PEAK
		else:
			visual.modulate = READY_TINT.lightened(0.06)
	elif hovering:
		visual.modulate = Color(1.08, 1.08, 1.08, 1.0)
	else:
		_update_ready_state()


func _on_selection_changed(_source: Node) -> void:
	_update_ready_state()


func _on_selection_cleared() -> void:
	_update_ready_state()


func _update_ready_state() -> void:
	_stop_ready_pulse()
	if visual == null:
		return

	var source := GameManager.selected_source
	if _can_discard(source) and _is_burnt_selection(source):
		_apply_panel_style(true, true)
		visual.modulate = BURNT_READY_TINT
		_start_burnt_pulse()
	elif _can_discard(source):
		_apply_panel_style(false, false)
		visual.modulate = READY_TINT
		visual.scale = Vector2.ONE
	elif _kitchen_has_burnt_food():
		_apply_panel_style(true, false)
		visual.modulate = BURNT_HINT_TINT
		visual.scale = Vector2.ONE
	else:
		_apply_panel_style(false, false)
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE


func _on_pressed() -> void:
	if GameManager.is_input_locked():
		return
	if not GameManager.has_selection():
		_flash_invalid()
		return

	var source := GameManager.selected_source
	if not _can_discard(source):
		_flash_invalid()
		return

	UiSfx.play_click()
	GameManager.clear_selection()
	_discard_source(source)
	_play_dump_fx()
	if dump_sfx and dump_sfx.stream:
		dump_sfx.play()
	_update_ready_state()


func _can_discard(source: Node) -> bool:
	if source == null or not source.has_method("get_item_data"):
		return false
	if source is ServingPlate:
		return (source as ServingPlate).has_food()
	if source is SelectableSource:
		var selectable := source as SelectableSource
		return selectable.is_occupied() and selectable.visible
	var item_data: Dictionary = source.get_item_data()
	return item_data.get("item_id", "") != ""


func _is_burnt_selection(source: Node) -> bool:
	if source == null or not source.has_method("get_item_data"):
		return false
	return source.get_item_data().get("item_state", "") == "overcooked"


func _kitchen_has_burnt_food() -> bool:
	var root := get_parent()
	if root == null:
		return false
	return _find_burnt_pickup(root) != null


func _find_burnt_pickup(node: Node) -> SelectableSource:
	if node is SelectableSource:
		var selectable := node as SelectableSource
		if selectable.visible and selectable.is_occupied() and selectable.item_state == "overcooked":
			return selectable
	for child in node.get_children():
		var found := _find_burnt_pickup(child)
		if found:
			return found
	return null


func _apply_panel_style(burnt: bool, strong: bool) -> void:
	if visual == null or not visual is PanelContainer:
		return
	var panel := visual as PanelContainer
	var base := panel.get_theme_stylebox("panel")
	if base == null or not base is StyleBoxFlat:
		return
	var style := base.duplicate() as StyleBoxFlat
	if burnt:
		style.bg_color = Color(0.42, 0.12, 0.06, 0.96) if strong else Color(0.32, 0.16, 0.1, 0.94)
		style.border_color = Color(1, 0.5, 0.08, 1) if strong else Color(0.95, 0.55, 0.18, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	else:
		style.bg_color = Color(0.22, 0.24, 0.28, 0.92)
		style.border_color = Color(0.45, 0.48, 0.52, 1)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)


func _start_burnt_pulse() -> void:
	if visual == null:
		return
	_stop_ready_pulse()
	visual.pivot_offset = visual.size * 0.5
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(visual, "modulate", BURNT_PULSE_PEAK, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(visual, "scale", Vector2(1.12, 1.12), 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "modulate", BURNT_READY_TINT, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(visual, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ready_pulse = tween


func _stop_ready_pulse() -> void:
	if _ready_pulse and _ready_pulse.is_valid():
		_ready_pulse.kill()
	_ready_pulse = null


func _discard_source(source: Node) -> void:
	if source is ServingPlate:
		(source as ServingPlate).reset_after_trash()
		return
	if source is SelectableSource:
		var selectable := source as SelectableSource
		selectable.occupied = false
		selectable.visible = false
		var station := _find_station_for_pickup(selectable)
		if station:
			station.clear_slot()
		return
	if source != null and source.has_method("clear_item"):
		source.clear_item()


func _find_station_for_pickup(pickup: SelectableSource) -> CookingStation:
	var parent := pickup.get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is CookingStation:
			var station := child as CookingStation
			if station.pickup_destination == pickup:
				return station
	return null


func _flash_invalid() -> void:
	if visual:
		var base := visual.modulate
		var tween := create_tween()
		tween.tween_property(visual, "modulate", INVALID_FLASH, 0.08)
		tween.tween_property(visual, "modulate", base, 0.14)
	var squash := create_tween()
	squash.tween_property(self, "modulate:a", 0.35, 0.06)
	squash.tween_property(self, "modulate:a", 0.02, 0.12)


func _play_dump_fx() -> void:
	var anchor := global_position + size * 0.5
	var parent := get_parent()
	if parent:
		KitchenFx.play_trash_dump(parent, anchor)
	if visual:
		var squash := create_tween()
		squash.tween_property(visual, "scale", Vector2(0.88, 0.72), 0.08)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		squash.tween_property(visual, "scale", Vector2.ONE, 0.16)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
