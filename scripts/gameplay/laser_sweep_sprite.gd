class_name LaserSweepSprite
extends AnimatedSprite2D
## Full-screen transparent laser sweep from PNG sequence in assets/vfx/png/.

signal sweep_finished

const FRAMES_DIR := "res://assets/vfx/png/lazer_video"
const FRAME_COUNT := 60
const ANIM := &"sweep"

@export var animation_fps: float = 24.0

var _ready_to_play: bool = false


func _ready() -> void:
	visible = false
	centered = false
	sprite_frames = _build_sprite_frames()
	_fit_to_viewport()
	_ready_to_play = sprite_frames != null and sprite_frames.has_animation(ANIM)
	animation_finished.connect(_on_animation_finished)


func is_configured() -> bool:
	return _ready_to_play


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(ANIM)
	frames.set_animation_speed(ANIM, animation_fps)
	frames.set_animation_loop(ANIM, false)

	for i in FRAME_COUNT:
		var path := "%s%02d.png" % [FRAMES_DIR, i]
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture:
			frames.add_frame(ANIM, texture)

	if frames.get_frame_count(ANIM) == 0:
		push_warning("LaserSweepSprite: no PNG frames found in %s" % FRAMES_DIR)
	return frames


func _fit_to_viewport() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(ANIM):
		return
	var texture := sprite_frames.get_frame_texture(ANIM, 0)
	if texture == null:
		return
	var frame_size := texture.get_size()
	position = Vector2(
		(KitchenLayout.VIEWPORT_SIZE.x - frame_size.x) * 0.5,
		(KitchenLayout.VIEWPORT_SIZE.y - frame_size.y) * 0.5
	)


func play_sweep() -> void:
	if not _ready_to_play:
		sweep_finished.emit()
		return
	visible = true
	frame = 0
	play(ANIM)


func sync_fps_to_sound(sound_player: AudioStreamPlayer2D) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(ANIM):
		return
	if sound_player == null or sound_player.stream == null:
		return
	var duration := sound_player.stream.get_length()
	if duration <= 0.0:
		return
	var frame_count := sprite_frames.get_frame_count(ANIM)
	animation_fps = frame_count / duration
	sprite_frames.set_animation_speed(ANIM, animation_fps)


func stop_sweep() -> void:
	stop()
	visible = false


func _on_animation_finished() -> void:
	visible = false
	sweep_finished.emit()
