class_name Juice
extends RefCounted

const SPRING_DURATION := KitchenLayout.JUICE_SPRING_DURATION


static func center_pivot(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5


static func elastic_pop_in(node: Control, duration: float = SPRING_DURATION) -> void:
	if node == null:
		return
	center_pivot(node)
	node.scale = Vector2.ZERO
	node.visible = true
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, duration)


static func elastic_show(node: Control, duration: float = SPRING_DURATION) -> void:
	elastic_pop_in(node, duration)


static func pop_scale(node: Control, peak: float = 1.15, duration: float = 0.15) -> void:
	if node == null:
		return
	center_pivot(node)
	var base := Vector2.ONE
	node.scale = base
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", base * peak, duration * 0.45)
	tween.tween_property(node, "scale", base, duration * 0.55)


static func fade_out(node: CanvasItem, duration: float = 0.35) -> Tween:
	if node == null:
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	return tween


static func fade_in(node: CanvasItem, duration: float = 0.4) -> Tween:
	if node == null:
		return null
	var c := node.modulate
	c.a = 0.0
	node.modulate = c
	node.visible = true
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween


static func flash_invalid(node: CanvasItem, flash_color: Color, base_color: Color = Color.WHITE) -> void:
	if node == null:
		return
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", flash_color, 0.08)
	tween.tween_property(node, "modulate", base_color, 0.12)


static func start_idle_bounce(node: Control, amount: float = 0.04, period: float = 0.9) -> Tween:
	if node == null:
		return null
	center_pivot(node)
	var base := node.scale
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", base * (1.0 + amount), period * 0.5)
	tween.tween_property(node, "scale", base * (1.0 - amount * 0.5), period * 0.5)
	return tween


static func tween_progress(bar: Range, target: float, duration: float = 0.12) -> void:
	if bar == null:
		return
	var tween := bar.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", target, duration)


static func celebrate_pop(node: Control, peak: float = 1.2) -> void:
	if node == null:
		return
	center_pivot(node)
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * peak, 0.18)
	tween.tween_property(node, "scale", Vector2.ONE, 0.28)
