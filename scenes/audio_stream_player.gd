extends AudioStreamPlayer

@export var background : AudioStream
@export var laser_background : AudioStream

func _ready() -> void:
	stream = background


func _on_laser_hazard_laser_started() -> void:
	stream = laser_background


func _on_laser_hazard_laser_finished() -> void:
	stream = background
