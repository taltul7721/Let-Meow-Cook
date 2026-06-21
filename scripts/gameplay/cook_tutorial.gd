extends CanvasLayer
## Quick opening overlay — visual cooking flows using in-game sprites.

signal finished

const PATH_BOARD := "res://assets/sprite/tools/board.png"
const PATH_STOVE := "res://assets/sprite/tools/stove.png"
const PATH_CAT := "res://assets/sprite/cat.png"
const PATH_CAT_VIP := "res://assets/sprite/cat_vip.png"
const GAME_TEAL := Color(0.498039, 0.756863, 0.74902, 1)
const GAME_TEAL_DARK := Color(0.28, 0.52, 0.58, 1)
const BUBBLE_WHITE := Color(1, 1, 1, 0.95)
const TEXT_DARK := Color(0.12, 0.18, 0.28, 1)
const TEXT_MUTED := Color(0.22, 0.32, 0.42, 1)
const ICON_FISH := Vector2(52, 34)
const ICON_TOOL := Vector2(54, 38)
const ICON_PLATE := Vector2(46, 30)
const ICON_CAT := Vector2(36, 44)
const ICON_CAT_VIP := Vector2(42, 50)

@onready var _panel: Control = %TutorialPanel
@onready var _steps: VBoxContainer = %StepsVBox
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	if _start_button:
		_start_button.pressed.connect(_dismiss)
	_build_visual_steps()


func start(on_done: Callable = Callable()) -> void:
	set_meta("_on_done", on_done)
	get_tree().paused = true
	_panel.visible = true
	show()


func _dismiss() -> void:
	_panel.visible = false
	hide()
	get_tree().paused = false
	var cb: Callable = get_meta("_on_done", Callable())
	if cb.is_valid():
		cb.call()
	finished.emit()


func _build_visual_steps() -> void:
	if _steps == null:
		return
	for child in _steps.get_children():
		child.queue_free()

	_add_step(
		"Sushi order",
		"Fridge → chop → plate → tap the cat with the plated food.",
		[
			[FishAssets.raw(), ICON_FISH],
			[load(PATH_BOARD) as Texture2D, ICON_TOOL],
			[FishAssets.cut(), ICON_FISH],
			[FishAssets.plate(), ICON_PLATE],
			[load(PATH_CAT) as Texture2D, ICON_CAT],
		]
	)

	_add_step(
		"Grilled order",
		"Fridge → grill → plate → tap the cat with the plated food.",
		[
			[FishAssets.raw(), ICON_FISH],
			[load(PATH_STOVE) as Texture2D, ICON_TOOL],
			[FishAssets.cooked(), ICON_FISH],
			[FishAssets.plate(), ICON_PLATE],
			[load(PATH_CAT) as Texture2D, ICON_CAT],
		]
	)

	_add_step(
		"VIP order",
		"Plate each dish, then serve both to the VIP cat.",
		[
			[FishAssets.cut(), ICON_FISH],
			[FishAssets.cooked(), ICON_FISH],
			[FishAssets.plate(), ICON_PLATE],
			[load(PATH_CAT_VIP) as Texture2D, ICON_CAT_VIP],
		],
		Color(0.82, 0.62, 0.12, 1.0)
	)


func _add_step(title: String, description: String, entries: Array, title_color: Color = GAME_TEAL_DARK) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(BUBBLE_WHITE, 14, Color(0.88, 0.92, 0.96, 0.8), 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_make_title(title, title_color))
	vbox.add_child(_make_flow_row(entries))
	vbox.add_child(_make_description(description))
	margin.add_child(vbox)
	card.add_child(margin)
	_steps.add_child(card)


func _card_style(bg: Color, radius: int, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	if border_w > 0:
		style.border_width_left = border_w
		style.border_width_top = border_w
		style.border_width_right = border_w
		style.border_width_bottom = border_w
		style.border_color = border
	style.shadow_color = Color(0.08, 0.12, 0.14, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _make_title(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.85))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _make_description(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(500.0, 0.0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.7))
	label.add_theme_constant_override("outline_size", 1)
	return label


func _make_flow_row(entries: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for i in entries.size():
		if i > 0:
			row.add_child(_make_arrow())
		var entry: Array = entries[i]
		row.add_child(_make_icon(entry[0] as Texture2D, entry[1] as Vector2))
	return row


func _make_arrow() -> Label:
	var arrow := Label.new()
	arrow.text = "→"
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", GAME_TEAL_DARK)
	arrow.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.85))
	arrow.add_theme_constant_override("outline_size", 2)
	return arrow


func _make_icon(tex: Texture2D, display_size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = display_size
	icon.size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	return icon
