extends AudioStreamPlayer

@export var background: AudioStream
@export var laser_background: AudioStream


func _ready() -> void:
	_start_background_music()


func _start_background_music() -> void:
	_play_stream(background)


func _play_stream(next: AudioStream) -> void:
	if next == null:
		return
	stream = next
	if next is AudioStreamOggVorbis:
		(next as AudioStreamOggVorbis).loop = true
	play()


func _on_laser_hazard_laser_started() -> void:
	_play_stream(laser_background)


func _on_laser_hazard_laser_finished() -> void:
	_play_stream(background)
