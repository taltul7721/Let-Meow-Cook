class_name ItemDisplay
extends RefCounted
## Fits artwork into explicit pixel boxes without distortion (KEEP_ASPECT_CENTERED).

const FISH_NATIVE_SIZE := Vector2(180, 120)
const PLATE_NATIVE_SIZE := Vector2(120, 66)


static func texture_pixel_size(tex: Texture2D) -> Vector2:
	if tex == null:
		return FISH_NATIVE_SIZE
	return tex.get_size()


static func apply_sized_button(btn: TextureButton, tex: Texture2D, display_size: Vector2) -> void:
	if btn == null or tex == null:
		return
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = display_size
	btn.size = display_size


static func apply_sized_rect(rect: TextureRect, tex: Texture2D, display_size: Vector2) -> void:
	if rect == null or tex == null:
		return
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = display_size
	rect.size = display_size


static func clear_button(btn: TextureButton) -> void:
	if btn == null:
		return
	btn.texture_normal = null
	btn.custom_minimum_size = Vector2.ZERO
	btn.size = Vector2.ZERO
	btn.visible = false
	btn.disabled = true


static func clear_rect(rect: TextureRect) -> void:
	if rect == null:
		return
	rect.texture = null
	rect.custom_minimum_size = Vector2.ZERO
	rect.size = Vector2.ZERO
	rect.visible = false


static func center_on_control(item: Control, anchor: Control) -> void:
	if item == null or anchor == null:
		return
	item.position = anchor.position + (anchor.size - item.size) * 0.5


static func center_in_control(item: Control, container: Control) -> void:
	if item == null or container == null:
		return
	item.position = container.size * 0.5 - item.size * 0.5


static func layout_ghost_on_anchor(
	ghost: TextureRect,
	anchor: Control,
	display_size: Vector2,
	y_offset: float,
	alpha: float
) -> void:
	if ghost == null or anchor == null:
		return
	ghost.custom_minimum_size = display_size
	ghost.size = display_size
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center_on_control(ghost, anchor)
	ghost.position.y += y_offset
	ghost.self_modulate = Color(1.0, 1.0, 1.0, alpha)
