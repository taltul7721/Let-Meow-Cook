class_name Laser
extends Node2D

@export var color : Color
@export var radius : float
@onready var shader : ShaderMaterial = $"../HunterVision/ColorRect".material
@onready var size : Vector2 = $"..".get_viewport().get_visible_rect().size
func _ready() -> void:
	position.y = size.y / 4

func _draw():
	draw_circle(position, radius, color)
	
func _set(property: StringName, value: Variant) -> bool:
	if property == "position":
		shader.set_shader_parameter("shader_parameter/position", Vector2(position.x / size.x, position.y / size.y))
	return false
