class_name ProgressBarStyle
extends RefCounted

const PATH_EMPTY := "res://assets/ui/Progress_Bar.png"
const PATH_FULL := "res://assets/ui/Progress_Bar_Full.png"
const TEX_SIZE_FALLBACK := Vector2(350, 30)

const WIDTH_BUBBLE := 112.0
const WIDTH_STATION := 128.0


static func get_tex_size() -> Vector2:
	var tex := load(PATH_EMPTY) as Texture2D
	if tex:
		return tex.get_size()
	return TEX_SIZE_FALLBACK


static func aspect_ratio() -> float:
	var tex_size := get_tex_size()
	return tex_size.y / tex_size.x


static func nine_patch_margin() -> int:
	return int(roundf(get_tex_size().y * 0.5))


static func apply(bar: TextureProgressBar) -> void:
	if bar == null:
		return
	bar.texture_under = load(PATH_EMPTY) as Texture2D
	bar.texture_progress = load(PATH_FULL) as Texture2D
	bar.nine_patch_stretch = true
	var margin := nine_patch_margin()
	bar.stretch_margin_left = margin
	bar.stretch_margin_right = margin
	bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	bar.min_value = 0.0
	bar.step = 0.001 if bar.max_value <= 1.0 else 0.05


static func size_for_width(width: float) -> Vector2:
	var w := maxf(width, 48.0)
	var h := roundf(w * aspect_ratio())
	return Vector2(w, maxf(h, 4.0))


static func fit(bar: TextureProgressBar, width: float) -> void:
	fit_at(bar, width, Vector2(bar.offset_left, bar.offset_top))


static func fit_at(bar: TextureProgressBar, width: float, pos: Vector2) -> void:
	if bar == null:
		return
	apply(bar)
	_apply_rect(bar, size_for_width(width), pos)


static func place_above(bar: TextureProgressBar, anchor: Control, gap: float = 6.0) -> void:
	if bar == null or anchor == null:
		return
	var sz := bar.size
	if sz.x <= 1.0:
		sz = size_for_width(WIDTH_STATION)
	var pos := anchor.position + Vector2(
		(anchor.size.x - sz.x) * 0.5,
		-sz.y - gap
	)
	_apply_rect(bar, sz, pos)


static func _apply_rect(bar: TextureProgressBar, sz: Vector2, pos: Vector2) -> void:
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.custom_minimum_size = sz
	bar.size = sz
	bar.offset_left = pos.x
	bar.offset_top = pos.y
	bar.offset_right = pos.x + sz.x
	bar.offset_bottom = pos.y + sz.y
