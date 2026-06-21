extends Node
## Session countdown — starts at two minutes and ticks down to zero.

signal time_expired

const FINAL_MINUTE_PITCH := 1.12
const VIGNETTE_START_SECONDS := 30.0
const VIGNETTE_MAX_INTENSITY := 0.88
const TIMER_PANIC_COLOR := Color(1.0, 0.32, 0.38, 1.0)

@export var timer_label: Label
@export var stress_vignette: ColorRect
@export var start_seconds: float = 120.0

var time_left: float = 0.0
var _expired: bool = false
var _running: bool = false
var _default_timer_color: Color = Color.WHITE


func _ready() -> void:
	time_left = start_seconds
	if timer_label:
		_default_timer_color = timer_label.get_theme_color(&"font_color")
	_update_label()
	_update_stress_effects()


func start_run() -> void:
	_running = true


func _process(delta: float) -> void:
	if _expired or not _running:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_label()
	_update_stress_effects()
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
	if time_left <= VIGNETTE_START_SECONDS:
		var panic := 1.0 - clampf(time_left / VIGNETTE_START_SECONDS, 0.0, 1.0)
		timer_label.add_theme_color_override(
			&"font_color",
			_default_timer_color.lerp(TIMER_PANIC_COLOR, panic)
		)
	else:
		timer_label.add_theme_color_override(&"font_color", _default_timer_color)


func _update_stress_effects() -> void:
	if time_left <= 60.0:
		var urgency := 1.0 - clampf(time_left / 60.0, 0.0, 1.0)
		MusicManager.set_main_pitch(lerpf(1.0, FINAL_MINUTE_PITCH, urgency))
	else:
		MusicManager.reset_main_pitch()

	if stress_vignette and stress_vignette.material is ShaderMaterial:
		var intensity := 0.0
		if time_left <= VIGNETTE_START_SECONDS:
			var vignette_t := 1.0 - clampf(time_left / VIGNETTE_START_SECONDS, 0.0, 1.0)
			intensity = lerpf(0.0, VIGNETTE_MAX_INTENSITY, vignette_t)
		(stress_vignette.material as ShaderMaterial).set_shader_parameter(&"intensity", intensity)
