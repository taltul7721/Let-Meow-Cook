extends CanvasLayer

const KITCHEN_SCENE := "res://scenes/demo_kitchen.tscn"

@onready var _panel: Control = %EndPanel
@onready var _score_label: Label = %FinalScoreValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_process_always(self)
	_panel.visible = false


func _set_process_always(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_process_always(child)


func show_result(final_score: int) -> void:
	if _score_label:
		_score_label.text = str(final_score)
	_panel.visible = true
	get_tree().paused = true
	MusicManager.set_muffled(true)


func _on_try_again_pressed() -> void:
	MusicManager.set_muffled(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(KITCHEN_SCENE)
