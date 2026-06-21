extends Node
## Shared UI tap sound for selections and placements.

const CLICK_PATH := "res://sounds/sfx/Click.ogg"

var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	_player.volume_db = 2.0
	_player.stream = load(CLICK_PATH) as AudioStream
	add_child(_player)


func play_click() -> void:
	if _player.stream == null:
		return
	_player.stop()
	_player.play()
