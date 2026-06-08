extends Control

@onready var _fridge_area: TextureButton = %FridgeArea
@onready var _fridge_bubble: Panel = %FridgeBubble
@onready var _fridge_fish: SelectableSource = %FridgeFish
@onready var _fridge_hint: Label = %FridgeHint
@onready var _board_drop: CookingStation = %BoardDrop
@onready var _board_ghost: TextureRect = %BoardGhostGuide
@onready var _board_processing: TextureRect = %BoardProcessingVisual
@onready var _board_progress: TextureProgressBar = %BoardProgress
@onready var _chop_particles: CPUParticles2D = %ChopParticles
@onready var _cut_pickup: SelectableSource = %CutPickup
@onready var _grill_drop: CookingStation = %GrillDrop
@onready var _grill_ghost: TextureRect = %GrillGhostGuide
@onready var _grill_processing: TextureRect = %GrillProcessingVisual
@onready var _grill_progress: TextureProgressBar = %GrillProgress
@onready var _sizzle_particles: CPUParticles2D = %SizzleParticles
@onready var _cooked_pickup: SelectableSource = %CookedPickup
@onready var _plate1: ServingPlate = %Plate1
@onready var _plate2: ServingPlate = %Plate2
@onready var _plate_visual1: TextureRect = %PlateVisual
@onready var _plate_visual2: TextureRect = %PlateVisual2
@onready var _plate_ghost1: TextureRect = %PlateGhostGuide
@onready var _plate_ghost2: TextureRect = %PlateGhostGuide2
@onready var _hint_label: Label = %HintLabel
@onready var _customer_layer: Control = %CustomerLayer
@onready var _counter_bar_front: TextureRect = %CounterBarFront
@onready var _timer_value: Label = %TimerValue
@onready var _laser_warning: Label = %LaserWarning

var _spawner: Node
var _run_timer: Node
var _fridge_hint_tween: Tween
var _plates: Array[ServingPlate] = []


func _ready() -> void:
	_ensure_customer_spawner()
	_ensure_run_timer()
	_spawner = get_node("CustomerSpawner")

	_make_invisible_zone(_fridge_area)
	_make_invisible_zone(_board_drop)
	_make_invisible_zone(_grill_drop)
	_disable_station_highlights()
	_configure_particles()
	_setup_progress_bars()
	_setup_hint_ui()

	_fridge_area.pressed.connect(_on_fridge_pressed)
	GameManager.selection_changed.connect(_on_selection_changed)
	GameManager.selection_cleared.connect(_on_selection_cleared)
	GameManager.placement_succeeded.connect(_on_placement_succeeded)
	GameManager.input_lock_changed.connect(_on_input_lock_changed)

	_setup_fridge_fish()
	_setup_board_station()
	_setup_grill_station()
	_plates = [_plate1, _plate2]
	_setup_plate(_plate1, _plate_visual1, %FoodVisual)
	_setup_plate(_plate2, _plate_visual2, %FoodVisual2)
	_setup_board_ghost()
	_setup_grill_ghost()
	_setup_plate_ghost()
	_setup_counter_bar_layer()
	_hide_editor_markers()

	if _spawner.has_signal("customer_spawned"):
		_spawner.customer_spawned.connect(_on_customer_spawned)

	call_deferred("_refresh_guides")


func get_active_customer() -> Customer:
	return _get_focus_customer()


func _ensure_run_timer() -> void:
	if has_node("RunTimer"):
		_run_timer = get_node("RunTimer")
		_run_timer.set("timer_label", _timer_value)
		return
	var timer_node := Node.new()
	timer_node.name = "RunTimer"
	timer_node.set_script(load("res://scripts/gameplay/run_timer.gd"))
	add_child(timer_node)
	timer_node.set("timer_label", _timer_value)
	_run_timer = timer_node


func _ensure_customer_spawner() -> void:
	if not has_node("CustomerSpawner"):
		var spawner_node := Node.new()
		spawner_node.name = "CustomerSpawner"
		spawner_node.set_script(load("res://scripts/gameplay/customer_spawner.gd"))
		add_child(spawner_node)
	var spawner := get_node("CustomerSpawner")
	spawner.set("spawn_parent", NodePath("CustomerLayer"))
	spawner.set("customer_scene", preload("res://scenes/customer.tscn"))
	spawner.set("score_label", get_node_or_null("ScorePanel/ScoreValue"))
	spawner.set("customer_count", 3)


func _make_invisible_zone(btn: TextureButton) -> void:
	btn.texture_normal = null
	btn.ignore_texture_size = true
	btn.modulate = Color(1, 1, 1, 0.01)


func _setup_progress_bars() -> void:
	ProgressBarStyle.fit(_board_progress, ProgressBarStyle.WIDTH_STATION)
	ProgressBarStyle.fit(_grill_progress, ProgressBarStyle.WIDTH_STATION)
	call_deferred("_refit_progress_bars")


func _refit_progress_bars() -> void:
	ProgressBarStyle.fit(_board_progress, ProgressBarStyle.WIDTH_STATION)
	ProgressBarStyle.fit(_grill_progress, ProgressBarStyle.WIDTH_STATION)


func _setup_hint_ui() -> void:
	if _fridge_hint:
		_fridge_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fridge_hint.visible = false
	if _hint_label:
		_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hide_editor_markers() -> void:
	for stand_name in ["CustomerStand1", "CustomerStand2", "CustomerStand3"]:
		var marker := get_node_or_null("%s/EditorMarker" % stand_name)
		if marker:
			marker.visible = false


func _disable_station_highlights() -> void:
	for station in [_fridge_area, _board_drop, _grill_drop]:
		if station.has_node("Highlight"):
			var hl: Node = station.get_node("Highlight")
			hl.visible = false
			hl.queue_free()


func _configure_particles() -> void:
	_configure_chop_particles(_chop_particles)
	_configure_sizzle_particles(_sizzle_particles)
	call_deferred("_sync_particle_positions")


func _sync_particle_positions() -> void:
	if _chop_particles:
		_chop_particles.position = _board_drop.position + _board_drop.size * 0.5
	if _sizzle_particles:
		_sizzle_particles.position = _grill_drop.position + _grill_drop.size * 0.5


func _configure_chop_particles(p: CPUParticles2D) -> void:
	if p == null:
		return
	p.z_index = 20
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 10
	p.lifetime = 0.4
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.gravity = Vector2(0, -120)
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.55
	p.color = Color(0.98, 0.96, 0.9, 0.9)


func _configure_sizzle_particles(p: CPUParticles2D) -> void:
	if p == null:
		return
	p.z_index = 20
	p.emitting = false
	p.one_shot = false
	p.explosiveness = 0.0
	p.amount = 14
	p.lifetime = 1.1
	p.direction = Vector2(0, -1)
	p.spread = 22.0
	p.gravity = Vector2(0, -50)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 28.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.7
	p.color = Color(0.78, 0.78, 0.82, 0.35)


func _setup_fridge_fish() -> void:
	_fridge_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fridge_fish.item_id = "fish"
	_fridge_fish.item_state = "raw"
	_fridge_fish.starts_occupied = true
	_fridge_fish.hide_when_cleared = true
	_fridge_fish.display_size = KitchenLayout.FRIDGE_FISH_SIZE
	_fridge_fish.spring_on_show = true
	call_deferred("_layout_fridge_fish")


func _layout_fridge_fish() -> void:
	ItemDisplay.apply_sized_button(_fridge_fish, FishAssets.raw(), KitchenLayout.FRIDGE_FISH_SIZE)
	ItemDisplay.center_in_control(_fridge_fish, _fridge_bubble)
	_fridge_fish.disabled = false


func _setup_board_station() -> void:
	_board_drop.accepted_item_ids = ["fish"]
	_board_drop.accepted_states = ["raw"]
	_board_drop.pickup_source = _cut_pickup
	_board_drop.output_texture = FishAssets.cut()
	_board_drop.cooking_display_texture = FishAssets.raw()
	_board_drop.processing_visual = _board_processing
	_board_drop.processing_display_size = KitchenLayout.BOARD_PROCESSING_SIZE
	_board_drop.pickup_display_size = KitchenLayout.STATION_PICKUP_SIZE
	_board_drop.progress_bar = _board_progress
	_board_drop.chop_particles = _chop_particles
	_board_drop.use_chop_poof = true
	_board_drop.set_fx_parent(self)
	_configure_station_pickup(_cut_pickup, FishAssets.cut(), "cut", _board_drop)


func _setup_grill_station() -> void:
	_grill_drop.accepted_item_ids = ["fish"]
	_grill_drop.accepted_states = ["cut"]
	_grill_drop.pickup_source = _cooked_pickup
	_grill_drop.output_texture = FishAssets.cooked()
	_grill_drop.cooking_display_texture = FishAssets.cut()
	_grill_drop.processing_visual = _grill_processing
	_grill_drop.processing_display_size = KitchenLayout.GRILL_PROCESSING_SIZE
	_grill_drop.pickup_display_size = KitchenLayout.STATION_PICKUP_SIZE
	_grill_drop.progress_bar = _grill_progress
	_grill_drop.sizzle_particles = _sizzle_particles
	_grill_drop.set_fx_parent(self)
	_configure_station_pickup(_cooked_pickup, FishAssets.cooked(), "cooked", _grill_drop)


func _setup_board_ghost() -> void:
	_board_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_ghost.z_index = 8
	_hide_board_ghost()


func _setup_grill_ghost() -> void:
	if _grill_ghost:
		_grill_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grill_ghost.z_index = 8
		_hide_grill_ghost()


func _setup_plate_ghost() -> void:
	for ghost in [_plate_ghost1, _plate_ghost2]:
		if ghost:
			ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ghost.z_index = 13
	_hide_plate_ghost()


func _configure_station_pickup(pickup: SelectableSource, tex: Texture2D, state: String, station: Control) -> void:
	pickup.item_id = "fish"
	pickup.item_state = state
	pickup.starts_occupied = false
	pickup.hide_when_cleared = true
	pickup.display_size = KitchenLayout.STATION_PICKUP_SIZE
	pickup.spring_on_show = false
	pickup.set_anchor_station(station)
	pickup._filled_texture = tex
	pickup.prepare_empty_pickup()


func _setup_counter_bar_layer() -> void:
	if _customer_layer:
		_customer_layer.z_index = KitchenLayout.CUSTOMER_LAYER_Z_INDEX
	if _counter_bar_front == null:
		return
	_counter_bar_front.z_index = KitchenLayout.COUNTER_BAR_Z_INDEX
	_counter_bar_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _counter_bar_front.texture == null and ResourceLoader.exists(KitchenLayout.PATH_COUNTER_BAR):
		_counter_bar_front.texture = load(KitchenLayout.PATH_COUNTER_BAR) as Texture2D
	var tex := _counter_bar_front.texture as Texture2D
	if tex == null:
		return
	# Keep position from the scene — only sync width/height to the bar art aspect ratio.
	var bar_w := KitchenLayout.VIEWPORT_SIZE.x
	var bar_h := bar_w * tex.get_size().y / tex.get_size().x
	_counter_bar_front.size = Vector2(bar_w, bar_h)
	_counter_bar_front.visible = true


func _setup_plate(plate: ServingPlate, visual: TextureRect, food: TextureRect) -> void:
	_make_invisible_zone(plate)
	plate.accepted_item_ids = ["fish"]
	plate.accepted_states = ["cut", "cooked"]
	plate.bind_visuals(visual, food)
	plate.plate_display_size = KitchenLayout.PLATE_DISPLAY_SIZE
	plate.plate_food_size = KitchenLayout.PLATE_FOOD_SIZE
	plate.plate_food_y_offset = KitchenLayout.PLATE_FOOD_Y_OFFSET
	plate.setup_plate_art(FishAssets.plate())


func _show_board_ghost() -> void:
	ItemDisplay.apply_sized_rect(_board_ghost, FishAssets.raw(), KitchenLayout.BOARD_GHOST_SIZE)
	ItemDisplay.center_on_control(_board_ghost, _board_drop)
	_board_ghost.modulate = Color(1, 1, 1, KitchenLayout.BOARD_GHOST_ALPHA)
	_board_ghost.visible = true


func _hide_board_ghost() -> void:
	if _board_ghost:
		_board_ghost.visible = false
		ItemDisplay.clear_rect(_board_ghost)


func _show_grill_ghost() -> void:
	if _grill_ghost == null:
		return
	ItemDisplay.apply_sized_rect(_grill_ghost, FishAssets.cut(), KitchenLayout.GRILL_PROCESSING_SIZE)
	ItemDisplay.center_on_control(_grill_ghost, _grill_drop)
	_grill_ghost.modulate = Color(1, 1, 1, KitchenLayout.BOARD_GHOST_ALPHA)
	_grill_ghost.visible = true


func _hide_grill_ghost() -> void:
	if _grill_ghost:
		_grill_ghost.visible = false
		ItemDisplay.clear_rect(_grill_ghost)


func _show_plate_ghost(tex: Texture2D, plate_visual: TextureRect, ghost: TextureRect) -> void:
	if ghost == null or plate_visual == null or tex == null:
		return
	ItemDisplay.apply_sized_rect(ghost, tex, KitchenLayout.PLATE_FOOD_SIZE)
	ItemDisplay.center_on_control(ghost, plate_visual)
	ghost.modulate = Color(1, 1, 1, KitchenLayout.PLATE_GHOST_ALPHA)
	ghost.visible = true


func _hide_plate_ghost() -> void:
	for ghost in [_plate_ghost1, _plate_ghost2]:
		if ghost:
			ghost.visible = false
			ItemDisplay.clear_rect(ghost)


func _find_empty_plate_for(item_data: Dictionary) -> ServingPlate:
	for plate in _plates:
		if plate and not plate.has_food() and not plate.is_respawning() and plate.can_accept(item_data):
			return plate
	return null


func _plate_visual_for(plate: ServingPlate) -> TextureRect:
	if plate == _plate1:
		return _plate_visual1
	if plate == _plate2:
		return _plate_visual2
	return null


func _plate_ghost_for(plate: ServingPlate) -> TextureRect:
	if plate == _plate1:
		return _plate_ghost1
	if plate == _plate2:
		return _plate_ghost2
	return null


func _any_plate_has_food() -> bool:
	for plate in _plates:
		if plate and plate.has_food():
			return true
	return false


func _selected_plate_with_food() -> ServingPlate:
	var selected := GameManager.selected_source
	if selected is ServingPlate and (selected as ServingPlate).has_food():
		return selected as ServingPlate
	return null


func _set_fridge_hint(active: bool) -> void:
	if _fridge_hint == null:
		return
	if _fridge_hint_tween and _fridge_hint_tween.is_valid():
		_fridge_hint_tween.kill()
		_fridge_hint_tween = null
	if not active:
		_fridge_hint.visible = false
		_fridge_hint.modulate = Color.WHITE
		return
	_fridge_hint.visible = true
	_fridge_hint_tween = create_tween().set_loops()
	_fridge_hint_tween.tween_property(_fridge_hint, "modulate:a", 0.35, 0.55)
	_fridge_hint_tween.tween_property(_fridge_hint, "modulate:a", 1.0, 0.55)


func _on_fridge_pressed() -> void:
	if GameManager.is_input_locked():
		return
	if _fridge_bubble.visible:
		_fridge_bubble.hide()
		_refresh_guides()
		return

	_fridge_bubble.show()
	_fridge_bubble.z_index = 22
	Juice.center_pivot(_fridge_bubble)
	Juice.elastic_pop_in(_fridge_bubble, KitchenLayout.JUICE_SPRING_DURATION)
	_layout_fridge_fish()
	if not _fridge_fish.is_occupied():
		_fridge_fish.refill_item("raw")
	_fridge_fish.visible = true
	_fridge_fish.disabled = false
	Juice.elastic_pop_in(_fridge_fish, KitchenLayout.JUICE_SPRING_DURATION)
	_refresh_guides()


func _on_customer_spawned(_customer: Customer) -> void:
	_refresh_guides()


func _on_selection_changed(source: Node) -> void:
	if source == _fridge_fish:
		_fridge_bubble.hide()
	_refresh_guides()


func _on_selection_cleared() -> void:
	_refresh_guides()


func _on_placement_succeeded(_source: Node, destination: Node) -> void:
	if destination == _board_drop:
		_hide_board_ghost()
	if destination == _grill_drop:
		_hide_grill_ghost()
	if destination in _plates:
		_hide_plate_ghost()
	_refresh_guides()


func _on_input_lock_changed(_locked: bool) -> void:
	_refresh_guides()


func _refresh_guides() -> void:
	if GameManager.is_input_locked():
		if _hint_label:
			_hint_label.text = "Laser! Stay still — you can't move!"
		_set_fridge_hint(false)
		_hide_board_ghost()
		_hide_grill_ghost()
		_hide_plate_ghost()
		for customer in _get_all_customers():
			if customer:
				customer.set_highlighted(false)
		for plate in _plates:
			if plate:
				plate.set_highlighted(false)
		return

	var item_data := GameManager.get_item_data()
	var has_sel := GameManager.has_selection()
	var state: String = str(item_data.get("item_state", ""))
	var focus_customer := _get_focus_customer()
	var needs_grill := _any_customer_wants_grill()

	# Fridge nudge — no item in hand yet.
	_set_fridge_hint(not has_sel and not _fridge_bubble.visible)

	# Board ghost — raw fish selected.
	if has_sel and state == "raw" and _board_drop.can_accept(item_data):
		_show_board_ghost()
	else:
		_hide_board_ghost()

	# Grill ghost — cut fish selected when any customer wants grilled food.
	if has_sel and state == "cut" and needs_grill and _grill_drop.can_accept(item_data):
		_show_grill_ghost()
	else:
		_hide_grill_ghost()

	# Plate ghost — show on every empty plate that can accept the selection.
	_hide_plate_ghost()
	if has_sel:
		var ghost_tex: Texture2D = FishAssets.for_state(state)
		if ghost_tex:
			for plate in _plates:
				if plate and not plate.has_food() and not plate.is_respawning() and plate.can_accept(item_data):
					var visual := _plate_visual_for(plate)
					var ghost := _plate_ghost_for(plate)
					_show_plate_ghost(ghost_tex, visual, ghost)

	# Plate highlights.
	for plate in _plates:
		if plate == null or plate.is_respawning():
			if plate:
				plate.set_highlighted(false)
			continue
		if has_sel and plate != GameManager.selected_source:
			plate.set_highlighted(plate.can_accept(item_data))
		elif plate == GameManager.selected_source:
			plate.set_highlighted(plate.has_food() or plate.can_accept(item_data))
		else:
			plate.set_highlighted(false)

	# Customer serve highlights — each cat lights up when its order can be served.
	var selected_plate := _selected_plate_with_food()
	for customer in _get_active_customers():
		var can_serve := selected_plate != null and customer.can_accept(selected_plate.get_item_data())
		customer.set_highlighted(can_serve)

	var plate_state: String = ""
	if selected_plate:
		plate_state = str(selected_plate.get_item_data().get("item_state", ""))
	if _hint_label:
		_hint_label.text = KitchenGuide.hint_for(
			has_sel,
			state,
			focus_customer,
			_fridge_bubble.visible,
			_board_drop.is_cooking(),
			_grill_drop.is_cooking(),
			_any_plate_has_food(),
			plate_state,
			_find_empty_plate_for(item_data) != null
		)
		%HintFlashAnimator.stop();
		if (_hint_label.text.contains("bubble")):
			%HintFlashAnimator.play("RESET");
		elif (_hint_label.text.contains("fridge")):
			%HintFlashAnimator.play("fridge_flash");
			
			


func _get_active_customers() -> Array[Customer]:
	if _spawner and _spawner.has_method("get_active_customers"):
		return _spawner.get_active_customers() as Array[Customer]
	return []


func _get_all_customers() -> Array[Customer]:
	if _spawner and _spawner.has_method("get_customers"):
		return _spawner.get_customers() as Array[Customer]
	return []


func _get_focus_customer() -> Customer:
	var active := _get_active_customers()
	if active.is_empty():
		return null
	var focus: Customer = active[0]
	var lowest := focus.get_patience_left()
	for customer in active:
		var left := customer.get_patience_left()
		if left < lowest:
			lowest = left
			focus = customer
	return focus


func _any_customer_wants_grill() -> bool:
	for customer in _get_active_customers():
		if customer.order_id == "cooked_fish":
			return true
	return false


func _get_active_customer() -> Customer:
	return _get_focus_customer()


func _on_fridge_area_pressed() -> void:
	pass # Replace with function body.
