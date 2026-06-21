extends Node

var _fridge_tutorial_done: bool = false


func _ready() -> void:
	GameManager.placement_succeeded.connect(on_placement)


func _on_fridge_pressed() -> void:
	UiSfx.play_click()
	_dismiss_fridge_tutorial()
	var opening: bool = not %FridgeBubble.visible
	%FridgeBubble.visible = opening
	if opening:
		%FridgeFish.occupied = true
		%FridgeFish.visible = true


func _on_ready() -> void:
	if not _fridge_tutorial_done:
		%FridgeHint.visible = true


func _dismiss_fridge_tutorial() -> void:
	if _fridge_tutorial_done:
		return
	_fridge_tutorial_done = true
	%FridgeHint.visible = false
	%HintLabel.visible = false
	%HintFlashAnimator.stop()


func _on_fridge_hint_visibility_changed() -> void:
	if _fridge_tutorial_done:
		return
	if %FridgeHint.visible:
		%HintFlashAnimator.play("RESET")
		%HintFlashAnimator.play("fridge_flash")
	elif %HintFlashAnimator.current_animation == "fridge_flash":
		%HintFlashAnimator.stop()


func on_placement(source: Node, destination: Node) -> void:
	if source == %FridgeFish:
		%FridgeBubble.visible = false
		%FridgeFish.visible = false
		%FridgeFish.occupied = false
		_dismiss_fridge_tutorial()
