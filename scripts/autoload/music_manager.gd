extends Node
## Persistent background + laser music across menu and gameplay.

const PATH_MAIN := "res://sounds/music/background_music.ogg"
const PATH_LASER := "res://sounds/music/lazer_music.ogg"
const PATH_CREDITS := "res://sounds/music/credits_music.mp3"
const MUSIC_BUS := &"Music"
const SFX_BOOST_DB := 8.0
const NORMAL_PITCH := 1.0
const MAIN_VOLUME_DB := -10.0
const LASER_VOLUME_DB := -8.0
const CREDITS_VOLUME_DB := -10.0
const FULL_CUTOFF_HZ := 20500.0
const MUFFLED_CUTOFF_HZ := 850.0
const FILTER_TWEEN_DURATION := 0.55

var _main: AudioStreamPlayer
var _laser: AudioStreamPlayer
var _credits: AudioStreamPlayer
var _music_bus_idx: int = -1
var _lowpass_slot: int = -1
var _filter_tween: Tween
var _muffle_depth: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_music_bus()

	_main = AudioStreamPlayer.new()
	_main.name = "MainMusic"
	_main.bus = MUSIC_BUS
	_main.volume_db = MAIN_VOLUME_DB
	add_child(_main)

	_laser = AudioStreamPlayer.new()
	_laser.name = "LaserMusic"
	_laser.bus = MUSIC_BUS
	_laser.volume_db = LASER_VOLUME_DB
	add_child(_laser)

	_credits = AudioStreamPlayer.new()
	_credits.name = "CreditsMusic"
	_credits.bus = MUSIC_BUS
	_credits.volume_db = CREDITS_VOLUME_DB
	add_child(_credits)

	var main_stream := load(PATH_MAIN) as AudioStream
	if main_stream is AudioStreamOggVorbis:
		(main_stream as AudioStreamOggVorbis).loop = true
	_main.stream = main_stream


func _setup_music_bus() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS)
		AudioServer.set_bus_send(_music_bus_idx, &"Master")

	var lowpass := _get_lowpass_effect()
	if lowpass == null:
		lowpass = AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = FULL_CUTOFF_HZ
		lowpass.resonance = 0.707
		_lowpass_slot = AudioServer.get_bus_effect_count(_music_bus_idx)
		AudioServer.add_bus_effect(_music_bus_idx, lowpass, _lowpass_slot)
	else:
		lowpass.cutoff_hz = FULL_CUTOFF_HZ
		_lowpass_slot = _find_lowpass_slot()


func _get_lowpass_effect() -> AudioEffectLowPassFilter:
	if _music_bus_idx < 0:
		return null
	for i in AudioServer.get_bus_effect_count(_music_bus_idx):
		var effect := AudioServer.get_bus_effect(_music_bus_idx, i)
		if effect is AudioEffectLowPassFilter:
			return effect as AudioEffectLowPassFilter
	return null


func _find_lowpass_slot() -> int:
	if _music_bus_idx < 0:
		return -1
	for i in AudioServer.get_bus_effect_count(_music_bus_idx):
		if AudioServer.get_bus_effect(_music_bus_idx, i) is AudioEffectLowPassFilter:
			return i
	return -1


func set_muffled(active: bool, duration: float = FILTER_TWEEN_DURATION) -> void:
	if active:
		_muffle_depth += 1
		if _muffle_depth == 1:
			_tween_lowpass(MUFFLED_CUTOFF_HZ, duration)
	else:
		_muffle_depth = maxi(_muffle_depth - 1, 0)
		if _muffle_depth == 0:
			_tween_lowpass(FULL_CUTOFF_HZ, duration)


func _tween_lowpass(target_hz: float, duration: float) -> void:
	var effect := _get_lowpass_effect()
	if effect == null:
		return
	if _filter_tween and _filter_tween.is_valid():
		_filter_tween.kill()
	var start_hz := effect.cutoff_hz
	if duration <= 0.0:
		effect.cutoff_hz = target_hz
		return
	_filter_tween = create_tween()
	_filter_tween.tween_method(_set_lowpass_cutoff, start_hz, target_hz, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_lowpass_cutoff(hz: float) -> void:
	var effect := _get_lowpass_effect()
	if effect:
		effect.cutoff_hz = hz


func play_main(from_start: bool = false) -> void:
	if _main.stream == null:
		return
	if from_start:
		_main.play(0.0)
		return
	if not _main.playing:
		_main.play()


func ensure_main_playing() -> void:
	if _main.stream == null:
		return
	_main.stream_paused = false
	if not _main.playing:
		_main.play()


func set_main_pitch(scale: float) -> void:
	_main.pitch_scale = maxf(scale, 0.01)


func reset_main_pitch() -> void:
	set_main_pitch(NORMAL_PITCH)


func on_laser_started() -> void:
	var laser_stream := load(PATH_LASER) as AudioStream
	if laser_stream is AudioStreamOggVorbis:
		(laser_stream as AudioStreamOggVorbis).loop = true
	if _main.playing:
		_main.stream_paused = true
	_laser.stream = laser_stream
	_laser.play()


func on_laser_finished() -> void:
	_laser.stop()
	_main.stream_paused = false
	if not _main.playing:
		_main.play()


func play_credits() -> void:
	var credits_stream := load(PATH_CREDITS) as AudioStream
	if credits_stream == null:
		return
	if credits_stream is AudioStreamMP3:
		(credits_stream as AudioStreamMP3).loop = true
	if _main.playing:
		_main.stream_paused = true
	_credits.stream = credits_stream
	_credits.play()


func stop_credits() -> void:
	if not _credits.playing:
		return
	_credits.stop()
	_main.stream_paused = false
	if not _main.playing:
		_main.play()


func boost_sfx_in(node: Node, volume_db: float = SFX_BOOST_DB) -> void:
	if node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).volume_db = volume_db
	for child in node.get_children():
		boost_sfx_in(child, volume_db)
