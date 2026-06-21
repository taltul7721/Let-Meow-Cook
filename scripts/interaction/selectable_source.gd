class_name SelectableSource
extends TextureButton
## Clickable food item fitted into an explicit display box.
@export var item_id: String
@export var item_state: String
@export var occupied : bool;
@export var flash_animation : String
@export var sfx : AudioStreamPlayer2D
@export var open_sfx : AudioStreamPlayer2D
@export var close_sfx : AudioStreamPlayer2D

func _ready() -> void:
	GameManager.placement_succeeded.connect(on_placement)

func _on_visibility_changed() -> void:
	if visible:
		var atlas_key := _atlas_key_for_state()
		(texture_normal as AtlasTexture).region.position = owner.atlas_coordinates[atlas_key]
		modulate = Color(0.14, 0.12, 0.12, 1.0) if item_state == "overcooked" else Color.WHITE
		%HintFlashAnimator.stop()
		%HintFlashAnimator.play(flash_animation)
		if open_sfx:
			open_sfx.play()
	else:
		modulate = Color.WHITE
		if close_sfx:
			close_sfx.play()


func _atlas_key_for_state() -> String:
	if item_state == "overcooked":
		return item_id + " cooked"
	return item_id + " " + item_state


func _on_pressed() -> void:
	GameManager.select(self)
	%HintFlashAnimator.stop()
	if sfx:
		sfx.play()
func get_item_data() -> Dictionary:
	return {"item_id": item_id, "item_state": item_state}
	
func is_occupied() -> bool:
	return occupied
	
func on_placement(source : Node, destination : Node) -> void:
	if source == self and source != %FridgeFish:
		occupied = false
		visible = false
		_clear_parent_station()


func _clear_parent_station() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		if child is CookingStation:
			var station := child as CookingStation
			if station.pickup_destination == self:
				station.clear_slot()
				return
