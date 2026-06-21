class_name ScorePopup
extends RefCounted
## Floating coin payout or penalty popup near the customer / HUD.

const COIN_PATH := "res://assets/ui/coin.png"
const POSITIVE_COLOR := Color(1.0, 0.93, 0.35, 1.0)
const NEGATIVE_COLOR := Color(1.0, 0.38, 0.38, 1.0)


static func play(
	parent: Node,
	amount: int,
	from_global: Vector2,
	score_panel: Control,
	score_label: Label,
	big: bool = false
) -> void:
	if parent == null or amount == 0:
		return

	var penalty := amount < 0
	var value := absi(amount)
	var host := Control.new()
	host.name = "ScorePopup"
	host.top_level = true
	host.z_as_relative = false
	host.z_index = 80
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(host)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	host.add_child(row)

	var coin := TextureRect.new()
	coin.texture = load(COIN_PATH) as Texture2D
	coin.custom_minimum_size = Vector2(56, 56) if big else Vector2(42, 42)
	coin.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if penalty:
		coin.modulate = Color(1.0, 0.55, 0.55, 1.0)
	row.add_child(coin)

	var label := Label.new()
	label.text = "-%d" % value if penalty else "+%d" % value
	label.add_theme_font_size_override("font_size", 54 if big else 40)
	var text_color := NEGATIVE_COLOR if penalty else POSITIVE_COLOR
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14, 1.0))
	label.add_theme_constant_override("outline_size", 5)
	row.add_child(label)

	host.global_position = from_global + Vector2(-30.0, -48.0)
	Juice.center_pivot(host)

	var rise := 88.0 if big else 64.0
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(host, "global_position:y", host.global_position.y - rise, 0.9)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(host, "scale", Vector2(1.18, 1.18) if big else Vector2(1.08, 1.08), 0.14)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(host, "modulate:a", 0.0, 0.45)\
		.set_delay(0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if score_panel:
		Juice.center_pivot(score_panel)
		var panel_peak := 1.12 if big else 1.08
		if penalty:
			panel_peak = 1.06
		Juice.pop_scale(score_panel, panel_peak, 0.24)
	if score_label:
		Juice.center_pivot(score_label)
		var label_peak := 1.18 if big else 1.12
		if penalty:
			label_peak = 1.1
		Juice.pop_scale(score_label, label_peak, 0.2)

	host.get_tree().create_timer(1.0).timeout.connect(host.queue_free)
