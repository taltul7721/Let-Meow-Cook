class_name ItemOutline
extends RefCounted
## Sprite-shaped outline via alpha edge detection (follows cat, fish, etc.).

const OUTLINE_SHADER := preload("res://shaders/outline_highlight.gdshader")

const DEFAULT_COLOR := Color(1.0, 0.92, 0.25, 1.0)
const DEFAULT_WIDTH := 2.5
const SERVE_COLOR := Color(0.45, 1.0, 0.55, 1.0)


static func apply_to(canvas_item: CanvasItem, outline_color: Color = DEFAULT_COLOR, width: float = DEFAULT_WIDTH) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("outline_width", width)
	mat.set_shader_parameter("enabled", false)
	canvas_item.material = mat
	return mat


static func set_enabled(material: ShaderMaterial, active: bool) -> void:
	if material:
		material.set_shader_parameter("enabled", active)
