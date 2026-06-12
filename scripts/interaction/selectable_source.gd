class_name SelectableSource
extends TextureButton
## Clickable food item fitted into an explicit display box.
@export var item_id: String
@export var item_state: String
@export var occupied : bool;
@export var flash_animation : String
@export var sfx : AudioStreamPlayer2D

func _ready() -> void:
	GameManager.placement_succeeded.connect(on_placement)

func _on_visibility_changed() -> void:
	if visible:
		(texture_normal as AtlasTexture).region.position = owner.atlas_coordinates[item_id + " " + item_state]
		%HintFlashAnimator.stop()
		%HintFlashAnimator.play(flash_animation)


func _on_pressed() -> void:
	GameManager.select(self)
	%HintFlashAnimator.stop()
	sfx.play()
func get_item_data() -> Dictionary:
	return {"item_id": item_id, "item_state": item_state}
	
func is_occupied() -> bool:
	return occupied
	
func on_placement(source : Node, destination : Node) -> void:
	if source == self and source != %FridgeFish:
		occupied = false
