extends CanvasLayer
## In-game pause overlay — keeps running while the tree is paused.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var _pause_button: Button = %PauseButton
@onready var _pause_panel: Control = %PausePanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_process_always(self)
	_pause_panel.visible = false


func _set_process_always(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_process_always(child)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	_pause_panel.visible = true
	if _pause_button:
		_pause_button.visible = false
	MusicManager.set_muffled(true)


func _resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false
	if _pause_button:
		_pause_button.visible = true
	MusicManager.set_muffled(false)


func _on_pause_button_pressed() -> void:
	_pause()


func _on_resume_pressed() -> void:
	_resume()


func _on_main_menu_pressed() -> void:
	UiSfx.play_click()
	_go_to_main_menu()


func _on_exit_pressed() -> void:
	UiSfx.play_click()
	get_tree().quit()


func _go_to_main_menu() -> void:
	MusicManager.set_muffled(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
