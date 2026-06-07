class_name Customer
extends Control
## Counter customer — cat behind the counter, order bubble above its head.

signal served_correct(order_id: String)
signal left_angry(order_id: String)

@export var patience_seconds: float = 15.0
@export var bubble_panel: Control
@export var bubble_item: TextureRect
@export var order_label: Label
@export var patience_bar: TextureProgressBar
@export var customer_sprite: TextureRect

const HIGHLIGHT_INVALID_FLASH := Color(1.6, 0.35, 0.35, 1.0)

var order_id: String = ""
var _time_left: float = 0.0
var _active: bool = false
var _idle_tween: Tween = null
var _last_patience_value: float = -1.0
var _cat_outline: ShaderMaterial
var _bubble_outline: ShaderMaterial


func is_active() -> bool:
	return _active


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
	if order_label == null and has_node("Bubble/OrderLabel"):
		order_label = get_node("Bubble/OrderLabel") as Label
	if patience_bar == null and has_node("Bubble/Patience"):
		patience_bar = get_node("Bubble/Patience") as TextureProgressBar
	if customer_sprite == null and has_node("CustomerSprite"):
		customer_sprite = get_node("CustomerSprite") as TextureRect
		_cat_outline = ItemOutline.apply_to(customer_sprite, ItemOutline.SERVE_COLOR, 3.0)
	if bubble_item:
		_bubble_outline = ItemOutline.apply_to(bubble_item, ItemOutline.DEFAULT_COLOR, 2.0)
	if has_node("ClickArea"):
		var click := get_node("ClickArea") as Control
		click.gui_input.connect(_on_click_area_input)


func _layout_cat_sprite() -> void:
	if customer_sprite == null:
		return
	var tex := customer_sprite.texture
	if tex == null:
		tex = load("res://assets/sprite/cat.png") as Texture2D
	if tex:
		ItemDisplay.apply_sized_rect(customer_sprite, tex, KitchenLayout.CAT_DISPLAY_SIZE)
	customer_sprite.position = Vector2(
		(size.x - customer_sprite.size.x) * 0.5,
		size.y - customer_sprite.size.y
	)
	_layout_overlays()


func _layout_overlays() -> void:
	if bubble_panel == null:
		return
	bubble_panel.custom_minimum_size = KitchenLayout.CUSTOMER_BUBBLE_SIZE
	bubble_panel.size = KitchenLayout.CUSTOMER_BUBBLE_SIZE
	bubble_panel.top_level = true
	bubble_panel.z_as_relative = false
	bubble_panel.z_index = KitchenLayout.CUSTOMER_OVERLAY_Z_INDEX
	bubble_panel.global_position = global_position + KitchenLayout.CUSTOMER_BUBBLE_OFFSET
	if patience_bar:
		ProgressBarStyle.fit_at(patience_bar, ProgressBarStyle.WIDTH_BUBBLE, Vector2(14, 12))


func start(order: String) -> void:
	order_id = order
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
	if not _active:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	_update_ui()
	if _time_left <= 0.0:
		_active = false
		_stop_idle_bounce()
		left_angry.emit(order_id)
		stop()


func can_accept(item_data: Dictionary) -> bool:
	if not _active:
		return false
	return _matches_order(item_data)


func receive_item(source: Node, item_data: Dictionary) -> void:
	if not _active:
		flash_invalid()
		return
	if not _matches_order(item_data):
		flash_invalid()
		return
	await _play_serve_celebration()
	if source is ServingPlate:
		(source as ServingPlate).consume_for_serve()
	elif source != null and source.has_method("clear_item"):
		source.clear_item()
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


func _matches_order(item_data: Dictionary) -> bool:
	var id: String = item_data.get("item_id", "")
	var state: String = item_data.get("item_state", "")
	match order_id:
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
	if bubble_item:
		var tex := FishAssets.for_order(order_id)
		if tex:
			ItemDisplay.apply_sized_rect(bubble_item, tex, KitchenLayout.CUSTOMER_BUBBLE_FOOD_SIZE)
		bubble_item.visible = _active and tex != null
	if order_label:
		order_label.visible = _active
		order_label.text = _order_display_text(order_id)
	if has_node("RecipeLabel"):
		var recipe := get_node("RecipeLabel") as Label
		recipe.visible = _active
		recipe.text = KitchenGuide.recipe_subtitle(order_id)
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


func _reset_ui() -> void:
	if customer_sprite:
		customer_sprite.visible = false
		customer_sprite.scale = Vector2.ONE
	if bubble_panel:
		bubble_panel.visible = false
		bubble_panel.scale = Vector2.ONE
	if bubble_item:
		bubble_item.texture = null
		bubble_item.visible = false
	if order_label:
		order_label.visible = false
	if has_node("RecipeLabel"):
		get_node("RecipeLabel").visible = false
	if patience_bar:
		patience_bar.visible = false
		patience_bar.modulate = Color.WHITE
	set_highlighted(false)


func _order_display_text(order: String) -> String:
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
		_idle_tween = Juice.start_idle_bounce(customer_sprite, 0.03, 1.1)


func _stop_idle_bounce() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	if customer_sprite:
		customer_sprite.scale = Vector2.ONE


func _play_serve_celebration() -> void:
	_stop_idle_bounce()
	if bubble_panel:
		Juice.celebrate_pop(bubble_panel, 1.18)
	if customer_sprite:
		Juice.celebrate_pop(customer_sprite, 1.12)
	var kitchen := get_tree().root.get_node_or_null("DemoKitchen")
	if kitchen:
		var anchor := global_position + Vector2(size.x * 0.5, size.y * 0.42)
		KitchenFx.play_serve_sparkle(kitchen, anchor)
	await get_tree().create_timer(0.35).timeout
