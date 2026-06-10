extends Node
## Session countdown — starts at two minutes and ticks down to zero.

signal time_expired

@export var timer_label: Label
@export var start_seconds: float = 15

var time_left: float = 0.0
var _expired: bool = false


func _ready() -> void:
	time_left = start_seconds
	_update_label()


func _process(delta: float) -> void:
	if _expired:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_label()
	if time_left <= 0.0:
		_expired = true
		time_expired.emit()


func _update_label() -> void:
	if timer_label == null:
		return
	var display_seconds := 0
	if time_left > 0.0:
		display_seconds = int(ceil(time_left))
	var minutes := display_seconds / 60
	var seconds := display_seconds % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
