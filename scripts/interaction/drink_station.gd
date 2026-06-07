class_name DrinkStation
extends CookingStation
## A CookingStation that starts cooking when clicked (no ingredient input).

@export var item_id: String = "tea"
@export var input_state: String = "brewing"


func _ready() -> void:
	super._ready()

	# CookingStation connects the base PlaceDestination click-to-place.
	# For drinks, clicking the station itself starts brewing instead.
	if pressed.is_connected(_on_pressed):
		pressed.disconnect(_on_pressed)
	pressed.connect(_on_drink_pressed)

## Drinks never accept placed items (so they should never glow as destinations).
func can_accept(_item_data: Dictionary) -> bool:
	return false


func _on_drink_pressed() -> void:
	# If player is holding something, this station doesn't accept it.
	if GameManager.has_selection():
		flash_invalid()
		return

	if _cooking:
		return

	if pickup_source != null and pickup_source.is_occupied():
		return

	# "Fake" an input item and reuse CookingStation's timer + output logic.
	_occupied = true
	_stored_item_id = item_id
	_stored_item_state = input_state
	_start_cooking({"item_id": item_id, "item_state": input_state})
