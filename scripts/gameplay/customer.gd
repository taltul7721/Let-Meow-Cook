class_name Customer
extends Control
## Counter customer — cat behind the counter, order bubble above its head.

signal served_correct(order_id: String)
signal left_angry(order_id: String)
signal served_wrong(order_id: String)
signal order_part_served()

const PATH_CAT := "res://assets/sprite/cat.png"
const PATH_CAT_VIP := "res://assets/sprite/cat_vip.png"
const VIP_ORDERS: Array[String] = ["sushi", "cooked_fish"]

@export var patience_seconds: float = 15.0
@export var vip_patience_seconds: float = 42.0
@export var bubble_panel: Control
@export var bubble_item: TextureRect
@export var bubble_item_2: TextureRect
@export var bubble_check_1: Label
@export var bubble_check_2: Label
@export var bubble_dish_1: Label
@export var bubble_dish_2: Label
@export var order_label: Label
@export var vip_badge: Label
@export var patience_bar: TextureProgressBar
@export var customer_sprite: TextureRect

const HIGHLIGHT_INVALID_FLASH := Color(1.6, 0.35, 0.35, 1.0)
const BUBBLE_TEXT := Color(0.1, 0.14, 0.22, 1.0)
const BUBBLE_TEXT_MUTED := Color(0.18, 0.24, 0.34, 1.0)
const BUBBLE_TEXT_DONE := Color(0.14, 0.52, 0.28, 1.0)
const BUBBLE_TEXT_OUTLINE := Color(1, 1, 1, 0.92)

var order_id: String = ""
var is_vip: bool = false
var order_ids: Array[String] = []
var _pending_orders: Array[String] = []
var _fulfilled_vip_orders: Array[String] = []
var _stand_slot: int = 1
var _time_left: float = 0.0
var _active: bool = false
var _idle_tween: Tween = null
var _last_patience_value: float = -1.0
var _serve_in_progress: bool = false
var _cat_outline: ShaderMaterial
var _bubble_outline: ShaderMaterial
var _bubble_outline_2: ShaderMaterial


func is_active() -> bool:
	return _active


func get_pending_orders() -> Array[String]:
	return _pending_orders.duplicate()


func is_vip_order_complete() -> bool:
	if not is_vip:
		return _pending_orders.is_empty()
	return _fulfilled_vip_orders.size() >= VIP_ORDERS.size()


func set_stand_slot(slot: int) -> void:
	_stand_slot = clampi(slot, 0, 2)
	if _active:
		_layout_overlays()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_nodes()
	_layout_cat_sprite()
	GameManager.selection_changed.connect(_on_selection_changed)
	GameManager.selection_cleared.connect(_on_selection_cleared)
	_reset_ui()
	visible = true


func _resolve_nodes() -> void:
	if bubble_panel == null and has_node("Bubble"):
		bubble_panel = get_node("Bubble") as Control
	if bubble_item == null and has_node("Bubble/BubbleItem"):
		bubble_item = get_node("Bubble/BubbleItem") as TextureRect
	if bubble_item_2 == null and has_node("Bubble/BubbleItem2"):
		bubble_item_2 = get_node("Bubble/BubbleItem2") as TextureRect
	if bubble_check_1 == null and has_node("Bubble/BubbleCheck1"):
		bubble_check_1 = get_node("Bubble/BubbleCheck1") as Label
	if bubble_check_2 == null and has_node("Bubble/BubbleCheck2"):
		bubble_check_2 = get_node("Bubble/BubbleCheck2") as Label
	if bubble_dish_1 == null and has_node("Bubble/BubbleDish1"):
		bubble_dish_1 = get_node("Bubble/BubbleDish1") as Label
	if bubble_dish_2 == null and has_node("Bubble/BubbleDish2"):
		bubble_dish_2 = get_node("Bubble/BubbleDish2") as Label
	for check in [bubble_check_1, bubble_check_2]:
		if check:
			check.z_index = 20
			check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for dish in [bubble_dish_1, bubble_dish_2]:
		if dish:
			dish.z_index = 8
			dish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if order_label == null and has_node("Bubble/OrderLabel"):
		order_label = get_node("Bubble/OrderLabel") as Label
	if vip_badge == null and has_node("Bubble/VipBadge"):
		vip_badge = get_node("Bubble/VipBadge") as Label
	if patience_bar == null and has_node("Bubble/Patience"):
		patience_bar = get_node("Bubble/Patience") as TextureProgressBar
	if customer_sprite == null and has_node("CustomerSprite"):
		customer_sprite = get_node("CustomerSprite") as TextureRect
	if customer_sprite and _cat_outline == null:
		_cat_outline = ItemOutline.apply_to(customer_sprite, ItemOutline.SERVE_COLOR, 3.0)
	if bubble_item and _bubble_outline == null:
		_bubble_outline = ItemOutline.apply_to(bubble_item, ItemOutline.DEFAULT_COLOR, 2.0)
	if bubble_item_2 and _bubble_outline_2 == null:
		_bubble_outline_2 = ItemOutline.apply_to(bubble_item_2, ItemOutline.DEFAULT_COLOR, 2.0)
	if has_node("ClickArea"):
		var click := get_node("ClickArea") as Control
		click.gui_input.connect(_on_click_area_input)


func _layout_cat_sprite() -> void:
	if customer_sprite == null:
		return
	var tex: Texture2D
	if is_vip:
		tex = load(PATH_CAT_VIP) as Texture2D
	else:
		tex = customer_sprite.texture
	if tex == null:
		tex = load(PATH_CAT) as Texture2D
	if tex:
		ItemDisplay.apply_sized_rect(customer_sprite, tex, KitchenLayout.CAT_DISPLAY_SIZE)
	if customer_sprite:
		var outline_color: Color = ItemOutline.VIP_COLOR if is_vip else ItemOutline.SERVE_COLOR
		var outline_width: float = 3.5 if is_vip else 3.0
		_cat_outline = ItemOutline.apply_to(customer_sprite, outline_color, outline_width)
		customer_sprite.modulate = Color(1.08, 1.02, 0.88, 1.0) if is_vip else Color.WHITE
	customer_sprite.position = Vector2(
		(size.x - customer_sprite.size.x) * 0.5,
		size.y - customer_sprite.size.y
	)
	if is_vip:
		customer_sprite.position.x += KitchenLayout.VIP_CAT_X_NUDGE
	_layout_overlays()


func _layout_overlays() -> void:
	if bubble_panel == null:
		return
	var bubble_size := KitchenLayout.CUSTOMER_BUBBLE_SIZE_VIP if is_vip else KitchenLayout.CUSTOMER_BUBBLE_SIZE
	bubble_panel.custom_minimum_size = bubble_size
	bubble_panel.size = bubble_size
	bubble_panel.top_level = true
	bubble_panel.z_as_relative = false
	bubble_panel.z_index = KitchenLayout.CUSTOMER_OVERLAY_Z_INDEX + (1 if is_vip else 0)
	bubble_panel.global_position = global_position + KitchenLayout.bubble_offset_for(
		_stand_slot, is_vip, size.x, bubble_size.x
	)
	if patience_bar:
		var bar_width := 120.0 if is_vip else ProgressBarStyle.WIDTH_BUBBLE
		var bar_x := (bubble_size.x - bar_width) * 0.5
		ProgressBarStyle.fit_at(patience_bar, bar_width, Vector2(bar_x, 12.0))
	if is_vip:
		_layout_vip_bubble_content(bubble_size)
	else:
		_layout_standard_bubble_content(bubble_size)


func _style_bubble_label(label: Label, font_size: int, color: Color, outline_size: int = 2) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", BUBBLE_TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", outline_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _layout_standard_bubble_content(bubble_size: Vector2) -> void:
	var pad := 8.0
	if order_label:
		order_label.offset_left = pad
		order_label.offset_right = bubble_size.x - pad
		order_label.offset_top = 62.0
		order_label.offset_bottom = 78.0
		_style_bubble_label(order_label, 14, BUBBLE_TEXT, 3)


func _layout_vip_bubble_content(bubble_size: Vector2) -> void:
	var pad := 10.0
	if vip_badge:
		var badge_w := 72.0
		vip_badge.offset_left = (bubble_size.x - badge_w) * 0.5
		vip_badge.offset_right = vip_badge.offset_left + badge_w
		vip_badge.offset_top = 16.0
		vip_badge.offset_bottom = 32.0
		_style_bubble_label(vip_badge, 12, Color(0.72, 0.52, 0.08, 1.0), 3)
	if order_label:
		order_label.offset_left = (bubble_size.x - 40.0) * 0.5
		order_label.offset_right = order_label.offset_left + 40.0
		order_label.offset_top = 84.0
		order_label.offset_bottom = 100.0
		_style_bubble_label(order_label, 13, BUBBLE_TEXT, 3)


func start(order: String, as_vip: bool = false) -> void:
	is_vip = as_vip
	if as_vip:
		order_id = "vip"
		order_ids = VIP_ORDERS.duplicate()
		_pending_orders = VIP_ORDERS.duplicate()
		_fulfilled_vip_orders.clear()
		patience_seconds = vip_patience_seconds
	else:
		order_id = order
		order_ids = [order]
		_pending_orders = [order]
		_fulfilled_vip_orders.clear()
	_time_left = patience_seconds
	_last_patience_value = -1.0
	_active = true
	visible = true
	show()
	_layout_cat_sprite()
	_update_ui()
	_play_spawn_juice()
	_start_idle_bounce()


func _play_spawn_juice() -> void:
	if customer_sprite:
		customer_sprite.visible = true
		Juice.elastic_pop_in(customer_sprite, KitchenLayout.JUICE_SPRING_DURATION)
	if bubble_panel and bubble_panel.visible:
		Juice.center_pivot(bubble_panel)
		Juice.elastic_pop_in(bubble_panel, KitchenLayout.JUICE_SPRING_DURATION)


func stop() -> void:
	_stop_idle_bounce()
	_active = false
	_reset_ui()


func _process(delta: float) -> void:
	if not _active or _serve_in_progress:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	_update_ui()
	if _time_left <= 0.0:
		_emit_left_angry()


func _emit_left_angry() -> void:
	if not _active or _serve_in_progress:
		return
	_active = false
	_stop_idle_bounce()
	left_angry.emit(order_id)
	stop()


func can_accept(item_data: Dictionary) -> bool:
	if not _active:
		return false
	if not GameManager.selected_source is ServingPlate:
		return false
	var plate := GameManager.selected_source as ServingPlate
	if not plate.has_food():
		return false
	return _matching_pending_order(item_data) != ""


func receive_item(source: Node, item_data: Dictionary) -> void:
	if not _active:
		flash_invalid()
		return
	if not source is ServingPlate:
		flash_invalid()
		return
	var plate := source as ServingPlate
	if not plate.has_food():
		flash_invalid()
		return
	var matched := _matching_pending_order(item_data)
	if matched == "":
		flash_invalid()
		served_wrong.emit(order_id)
		return
	if is_vip and matched in _fulfilled_vip_orders:
		flash_invalid()
		served_wrong.emit(order_id)
		return

	var vip_finishing := is_vip and _pending_orders.size() == 1
	_serve_in_progress = true
	await _play_serve_celebration(vip_finishing)
	_serve_in_progress = false
	if not _active:
		return

	plate.consume_for_serve()

	_pending_orders.erase(matched)
	if is_vip:
		_fulfilled_vip_orders.append(matched)
		if _fulfilled_vip_orders.size() < VIP_ORDERS.size():
			order_part_served.emit()
			_update_ui()
			_play_partial_vip_juice()
			_start_idle_bounce()
			return

	served_correct.emit(order_id)
	stop()


func set_highlighted(active: bool) -> void:
	if not _active:
		return
	ItemOutline.set_enabled(_cat_outline, active)
	var hl := get_node_or_null("Highlight") as ColorRect
	if hl:
		hl.visible = false
	if customer_sprite and _cat_outline == null:
		var target: Color = Color(1.15, 1.1, 1.05) if active else Color.WHITE
		var tween := create_tween()
		tween.tween_property(customer_sprite, "modulate", target, 0.12)
	elif customer_sprite and not active:
		customer_sprite.modulate = Color.WHITE


func flash_invalid() -> void:
	if customer_sprite:
		Juice.flash_invalid(customer_sprite, HIGHLIGHT_INVALID_FLASH)
	if has_node("Highlight") and get_node("Highlight") is CanvasItem:
		Juice.flash_invalid(get_node("Highlight") as CanvasItem, HIGHLIGHT_INVALID_FLASH)


func get_patience_left() -> float:
	return _time_left


func _on_click_area_input(event: InputEvent) -> void:
	if not _active or GameManager.is_input_locked():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			GameManager.try_place(self)
			accept_event()


func _on_selection_changed(_source: Node) -> void:
	_update_serve_hint()


func _on_selection_cleared() -> void:
	_update_serve_hint()


func _update_serve_hint() -> void:
	if not _active:
		set_highlighted(false)
		return
	if not GameManager.has_selection():
		set_highlighted(false)
		return
	set_highlighted(can_accept(GameManager.get_item_data()))


func _matching_pending_order(item_data: Dictionary) -> String:
	var id: String = item_data.get("item_id", "")
	var state: String = item_data.get("item_state", "")
	for pending in _pending_orders:
		if _order_matches_item(pending, id, state):
			return pending
	return ""


func _order_matches_item(order: String, id: String, state: String) -> bool:
	match order:
		"sushi":
			return id == "fish" and state == "cut"
		"cooked_fish":
			return id == "fish" and state == "cooked"
		_:
			return false


func _update_ui() -> void:
	if customer_sprite:
		customer_sprite.visible = _active
	if bubble_panel:
		bubble_panel.visible = _active
	if vip_badge:
		vip_badge.visible = _active and is_vip
	if is_vip:
		_update_vip_bubble_items()
	else:
		if bubble_item:
			bubble_item.visible = _active
			bubble_item.position = Vector2(
				(bubble_panel.size.x - KitchenLayout.CUSTOMER_BUBBLE_FOOD_SIZE.x) * 0.5,
				26.0
			)
			var tex: Texture2D = FishAssets.for_order(order_ids[0]) if order_ids.size() > 0 else null
			if tex:
				ItemDisplay.apply_sized_rect(bubble_item, tex, KitchenLayout.CUSTOMER_BUBBLE_FOOD_SIZE)
		if bubble_item_2:
			bubble_item_2.visible = false
		for extra in [bubble_check_1, bubble_check_2, bubble_dish_1, bubble_dish_2]:
			if extra:
				extra.visible = false
	if order_label:
		order_label.visible = _active
		order_label.text = _order_display_text()
	if has_node("Bubble/RecipeLabel"):
		get_node("Bubble/RecipeLabel").visible = false
	if patience_bar:
		patience_bar.visible = _active
		patience_bar.max_value = patience_seconds
		if absf(_time_left - _last_patience_value) > 0.05:
			Juice.tween_progress(patience_bar, _time_left, 0.15)
			_last_patience_value = _time_left
		if _time_left < patience_seconds * 0.35:
			patience_bar.modulate = Color(1.15, 0.75, 0.65)
		else:
			patience_bar.modulate = Color.WHITE


func _update_vip_bubble_items() -> void:
	var slots: Array[TextureRect] = [bubble_item, bubble_item_2]
	var checks: Array[Label] = [bubble_check_1, bubble_check_2]
	var dish_labels: Array[Label] = [bubble_dish_1, bubble_dish_2]
	var item_size := KitchenLayout.CUSTOMER_BUBBLE_FOOD_SIZE * 0.88
	var gap := 12.0
	var row_w := item_size.x * 2.0 + gap
	var start_x := (bubble_panel.size.x - row_w) * 0.5
	var y := 32.0
	for i in VIP_ORDERS.size():
		if i >= slots.size() or slots[i] == null:
			continue
		var slot: TextureRect = slots[i]
		var order: String = VIP_ORDERS[i]
		slot.position = Vector2(start_x + i * (item_size.x + gap), y)
		var tex := FishAssets.for_order(order)
		if tex:
			ItemDisplay.apply_sized_rect(slot, tex, item_size)
		slot.visible = _active
		var fulfilled: bool = order in _fulfilled_vip_orders
		slot.modulate = Color(0.72, 0.76, 0.8, 0.5) if fulfilled else Color.WHITE
		slot.scale = Vector2.ONE
		if i < checks.size() and checks[i] != null:
			var check: Label = checks[i]
			check.visible = _active and fulfilled
			check.position = slot.position + Vector2(item_size.x * 0.5 - 12.0, item_size.y * 0.5 - 14.0)
		if i < dish_labels.size() and dish_labels[i] != null:
			var dish: Label = dish_labels[i]
			dish.visible = _active
			dish.text = _vip_dish_name(order)
			dish.position = Vector2(slot.position.x - 2.0, slot.position.y + item_size.y + 2.0)
			dish.size = Vector2(item_size.x + 4.0, 14.0)
			var dish_color := BUBBLE_TEXT_DONE if fulfilled else BUBBLE_TEXT
			_style_bubble_label(dish, 11, dish_color, 2 if fulfilled else 3)
			if fulfilled:
				dish.text = "✓ " + dish.text


func _reset_ui() -> void:
	if customer_sprite:
		customer_sprite.visible = false
		customer_sprite.scale = Vector2.ONE
		customer_sprite.modulate = Color.WHITE
	if bubble_panel:
		bubble_panel.visible = false
		bubble_panel.scale = Vector2.ONE
	if bubble_item:
		bubble_item.texture = null
		bubble_item.visible = false
		bubble_item.modulate = Color.WHITE
		bubble_item.scale = Vector2.ONE
	if bubble_item_2:
		bubble_item_2.texture = null
		bubble_item_2.visible = false
		bubble_item_2.modulate = Color.WHITE
		bubble_item_2.scale = Vector2.ONE
	if bubble_check_1:
		bubble_check_1.visible = false
	if bubble_check_2:
		bubble_check_2.visible = false
	if bubble_dish_1:
		bubble_dish_1.visible = false
	if bubble_dish_2:
		bubble_dish_2.visible = false
	if vip_badge:
		vip_badge.visible = false
	if order_label:
		order_label.visible = false
	if has_node("RecipeLabel"):
		get_node("RecipeLabel").visible = false
	if patience_bar:
		patience_bar.visible = false
		patience_bar.modulate = Color.WHITE
	set_highlighted(false)


func _order_display_text() -> String:
	if is_vip:
		return "%d/2" % _fulfilled_vip_orders.size()
	match order_id:
		"sushi":
			return "Sushi"
		"cooked_fish":
			return "Grilled"
		_:
			return "?"


func _vip_dish_name(order: String) -> String:
	match order:
		"sushi":
			return "Sushi"
		"cooked_fish":
			return "Grilled"
		_:
			return "?"


func _start_idle_bounce() -> void:
	_stop_idle_bounce()
	if customer_sprite:
		var amount := 0.04 if not is_vip else 0.05
		_idle_tween = Juice.start_idle_bounce(customer_sprite, amount, 1.1)


func _stop_idle_bounce() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	if customer_sprite:
		customer_sprite.scale = Vector2.ONE


func _play_partial_vip_juice() -> void:
	if bubble_panel:
		Juice.celebrate_pop(bubble_panel, 1.1)
	if customer_sprite:
		Juice.pop_scale(customer_sprite, 1.08, 0.18)


func _play_serve_celebration(big: bool = false) -> void:
	_stop_idle_bounce()
	var peak := 1.28 if big else 1.18
	if bubble_panel:
		Juice.celebrate_pop(bubble_panel, peak)
	if customer_sprite:
		Juice.celebrate_pop(customer_sprite, peak - 0.06)
	var kitchen := get_tree().root.get_node_or_null("DemoKitchen")
	if kitchen:
		var anchor := global_position + Vector2(size.x * 0.5, size.y * 0.42)
		KitchenFx.play_serve_sparkle(kitchen, anchor)
		if big:
			KitchenFx.play_serve_sparkle(kitchen, anchor + Vector2(18, -8))
	await get_tree().create_timer(0.35 if big else 0.28).timeout
