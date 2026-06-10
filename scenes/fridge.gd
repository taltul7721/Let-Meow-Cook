extends Node

func _ready() -> void:
	GameManager.placement_succeeded.connect(on_placement)

func _on_fridge_pressed() -> void: 
	%FridgeBubble.visible = not %FridgeBubble.visible;
	%FridgeHint.visible = false;

func _on_ready() -> void:
	%FridgeHint.visible = true;
	
func _on_fridge_hint_visibility_changed() -> void:
	if %FridgeHint.visible:
		%HintFlashAnimator.play("RESET")
		%HintFlashAnimator.play("fridge_flash")
	elif %HintFlashAnimator.current_animation == "fridge_flash":
		print("fridge")
		%HintFlashAnimator.stop();

func on_placement(source : Node, destination : Node) -> void:
	if source == %FridgeFish:
		%FridgeBubble.visible = false
