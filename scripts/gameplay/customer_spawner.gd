extends Node

@export var spawn_parent : Node
@export var customer_scene: PackedScene
@export var score_label: Label
@export var respawn_delay_min: float = 2.0
@export var respawn_delay_max: float = 5.5
@export var serve_points: int = 50
@export var vip_part_points: int = 65
@export var vip_finish_points: int = 75
@export var vip_spawn_chance: float = 0.3
@export var angry_penalty: int = 5
@export var customer_count: int = 3
@export var initial_spawn_delays: Array[float] = [0.5, 5.0, 12.0]
@export var meow_sfx : AudioStreamPlayer2D
@export var complete_order_sfx : AudioStreamPlayer2D
@export var partial_order_sfx : AudioStreamPlayer2D
@export var correct_order_sfx : AudioStreamPlayer2D
@export var wrong_order_sfx : AudioStreamPlayer2D
@export var enter_sfx : AudioStreamPlayer2D
@export var angry_meow_sfx : AudioStreamPlayer2D
@export var stands_success_animation : Array[AnimationPlayer]

const STAND_NAMES := ["CustomerStand1", "CustomerStand2", "CustomerStand3"]
const ORDER_OPTIONS := ["sushi", "cooked_fish"]
const MEOW_PATHS: Array[String] = [
	"res://sounds/sfx/Meows/Meow_01.ogg",
	"res://sounds/sfx/Meows/Meow_02.ogg",
	"res://sounds/sfx/Meows/Meow_03.ogg",
	"res://sounds/sfx/Meows/Meow_04.ogg",
]
const ANGRY_MEOW_PATHS: Array[String] = [
	"res://sounds/sfx/Meows/Meow_angry_01.ogg",
	"res://sounds/sfx/Meows/Meow_angry_02.ogg",
	"res://sounds/sfx/Meows/Meow_angry_03.ogg",
	"res://sounds/sfx/Meows/Meow_angry_04.ogg",
]

var score: int = 0
var _customers: Array[Customer] = []
var _spawn_pending: Array[bool] = []
var _meow_index: int = 0
var _angry_meow_index: int = 0

signal customer_spawned(customer: Customer)


func get_score() -> int:
	return score


func _ready() -> void:
	if customer_scene == null:
		customer_scene = preload("res://scenes/customer.tscn")
	_customers.resize(customer_count)
	_spawn_pending.resize(customer_count)
	for i in customer_count:
		_spawn_pending[i] = false
	call_deferred("_update_score")


func start_spawning() -> void:
	if not is_inside_tree():
		return
	_begin_customer_flow()


func get_active_customer() -> Customer:
	for customer in _customers:
		if customer and customer.is_active():
			return customer
	return null


func get_active_customers() -> Array[Customer]:
	var result: Array[Customer] = []
	for customer in _customers:
		if customer and customer.is_active():
			result.append(customer)
	return result


func get_customers() -> Array[Customer]:
	var result: Array[Customer] = []
	for customer in _customers:
		if customer:
			result.append(customer)
	return result


func _begin_customer_flow() -> void:
	for slot in customer_count:
		_queue_spawn(slot, _initial_delay_for_slot(slot))
	_start_slot_maintenance()


func _start_slot_maintenance() -> void:
	while is_inside_tree():
		await get_tree().create_timer(2.0).timeout
		for slot in customer_count:
			if _slot_needs_customer(slot):
				_queue_spawn(slot, _random_respawn_delay() * 0.5)


func _slot_needs_customer(slot: int) -> bool:
	if _spawn_pending[slot]:
		return false
	var customer := _customers[slot]
	if customer == null or not is_instance_valid(customer):
		return true
	return not customer.is_active()


func _initial_delay_for_slot(slot: int) -> float:
	if slot >= 0 and slot < initial_spawn_delays.size():
		return maxf(initial_spawn_delays[slot], 0.0)
	return float(slot) * 4.0


func _queue_spawn(slot: int, delay: float) -> void:
	if slot < 0 or slot >= customer_count:
		return
	if _spawn_pending[slot]:
		return
	_spawn_pending[slot] = true
	var timer := get_tree().create_timer(maxf(delay, 0.1))
	timer.timeout.connect(func() -> void:
		_spawn_pending[slot] = false
		if is_inside_tree() and _slot_needs_customer(slot):
			_spawn_at_slot(slot)
	, CONNECT_ONE_SHOT)


func _spawn_at_slot(slot: int) -> void:
	if slot < 0 or slot >= customer_count:
		return
	_clear_slot(slot)

	var parent: Node = _resolve_spawn_parent()
	if parent == null:
		push_error("CustomerSpawner: could not find CustomerLayer.")
		_queue_spawn(slot, 1.0)
		return

	var customer := customer_scene.instantiate() as Customer
	if customer == null:
		push_error("CustomerSpawner: customer_scene must instantiate a Customer.")
		_queue_spawn(slot, 1.0)
		return

	parent.add_child(customer)
	customer.z_index = KitchenLayout.CUSTOMER_LAYER_Z_INDEX
	_place_at_stand(customer, slot)
	customer.visible = true
	customer.show()

	customer.served_correct.connect(_on_served_correct.bind(slot), CONNECT_ONE_SHOT)
	customer.served_wrong.connect(_on_served_wrong.bind(slot), CONNECT_ONE_SHOT)
	customer.left_angry.connect(_on_left_angry.bind(slot), CONNECT_ONE_SHOT)
	customer.order_part_served.connect(_on_order_part_served.bind(slot), CONNECT_ONE_SHOT)

	var as_vip: bool = randf() < vip_spawn_chance
	if as_vip:
		customer.start("vip", true)
	else:
		customer.start(_pick_order(), false)

	_customers[slot] = customer
	customer_spawned.emit(customer)
	_play_customer_enter()


func _place_at_stand(customer: Control, slot: int) -> void:
	var feet := _resolve_feet_position(slot)
	var sz := customer.size
	customer.position = Vector2(feet.x - sz.x * 0.5, feet.y - sz.y)
	if customer.has_method("set_stand_slot"):
		customer.set_stand_slot(slot)
	if customer.has_method("_layout_cat_sprite"):
		customer.call("_layout_cat_sprite")


func _resolve_feet_position(slot: int) -> Vector2:
	var kitchen := _get_demo_kitchen()
	if kitchen and slot < STAND_NAMES.size():
		var stand := kitchen.get_node_or_null(STAND_NAMES[slot]) as Control
		if stand:
			return stand.position + Vector2(stand.size.x * 0.5, stand.size.y)
	return KitchenLayout.CUSTOMER_STAND


func _resolve_spawn_parent() -> Node:
	return spawn_parent


func _get_demo_kitchen() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var current := tree.current_scene
	if current != null and current.name == "DemoKitchen":
		return current
	return tree.root.get_node_or_null("DemoKitchen")


func _clear_slot(slot: int) -> void:
	if slot < 0 or slot >= _customers.size():
		return
	var customer := _customers[slot]
	if customer == null:
		return
	if is_instance_valid(customer):
		customer.queue_free()
	_customers[slot] = null


func _active_order_ids() -> Array[String]:
	var orders: Array[String] = []
	for customer in _customers:
		if customer and customer.is_active():
			if customer.is_vip:
				for pending in customer.get_pending_orders():
					if pending not in orders:
						orders.append(pending)
			elif customer.order_id not in orders:
				orders.append(customer.order_id)
	return orders


func _pick_order() -> String:
	var active := _active_order_ids()
	var candidates: Array[String] = []
	for order_id in ORDER_OPTIONS:
		if order_id not in active:
			candidates.append(order_id)
	if candidates.is_empty():
		return ORDER_OPTIONS[randi() % ORDER_OPTIONS.size()]
	return candidates[randi() % candidates.size()]


func _random_respawn_delay() -> float:
	var min_delay := minf(respawn_delay_min, respawn_delay_max)
	var max_delay := maxf(respawn_delay_min, respawn_delay_max)
	return randf_range(min_delay, max_delay)


func _play_customer_enter() -> void:
	if enter_sfx and enter_sfx.stream:
		enter_sfx.stop()
		enter_sfx.play()
	_play_customer_meow()


func _play_customer_meow() -> void:
	var player := meow_sfx if meow_sfx != null else enter_sfx
	if player == null:
		return
	var path := MEOW_PATHS[_meow_index]
	_meow_index = (_meow_index + 1) % MEOW_PATHS.size()
	var stream := load(path) as AudioStream
	if stream == null:
		return
	player.stream = stream
	player.stop()
	player.play()


func _play_angry_meow() -> void:
	var player := angry_meow_sfx if angry_meow_sfx != null else meow_sfx
	if player == null:
		return
	var path := ANGRY_MEOW_PATHS[_angry_meow_index]
	_angry_meow_index = (_angry_meow_index + 1) % ANGRY_MEOW_PATHS.size()
	var stream := load(path) as AudioStream
	if stream == null:
		return
	player.stream = stream
	player.stop()
	player.play()


func _play_served_sfx() -> void:
	var player := partial_order_sfx if partial_order_sfx != null else correct_order_sfx
	if player and player.stream:
		player.stop()
		player.play()


func _play_complete_sfx() -> void:
	var player := complete_order_sfx if complete_order_sfx != null else correct_order_sfx
	if player and player.stream:
		player.stop()
		player.play()


func _resolve_score_label() -> Label:
	if score_label != null and is_instance_valid(score_label):
		return score_label
	var kitchen := _get_demo_kitchen()
	if kitchen == null:
		return null
	if kitchen.has_node("%ScoreValue"):
		return kitchen.get_node("%ScoreValue") as Label
	return kitchen.get_node_or_null("ScorePanel/ScoreValue") as Label


func _resolve_score_panel() -> Control:
	var kitchen := _get_demo_kitchen()
	if kitchen == null:
		return null
	if kitchen.has_node("%ScorePanel"):
		return kitchen.get_node("%ScorePanel") as Control
	return kitchen.get_node_or_null("ScorePanel") as Control


func _award_points(amount: int, customer: Customer, big_popup: bool) -> void:
	if amount <= 0:
		return
	score += amount
	_set_score_text()
	var kitchen := _get_demo_kitchen()
	if kitchen == null:
		return
	var panel := _resolve_score_panel()
	var label := _resolve_score_label()
	var anchor := Vector2(576.0, 120.0)
	if customer and is_instance_valid(customer):
		anchor = customer.global_position + Vector2(customer.size.x * 0.5, 72.0)
	ScorePopup.play(kitchen, amount, anchor, panel, label, big_popup)


func _apply_penalty(amount: int, customer: Customer) -> void:
	if amount <= 0:
		return
	score = max(score - amount, 0)
	_set_score_text()
	var kitchen := _get_demo_kitchen()
	if kitchen == null:
		return
	var panel := _resolve_score_panel()
	var label := _resolve_score_label()
	var anchor := Vector2(576.0, 120.0)
	if customer and is_instance_valid(customer):
		anchor = customer.global_position + Vector2(customer.size.x * 0.5, 72.0)
	ScorePopup.play(kitchen, -amount, anchor, panel, label, false)
	if customer and is_instance_valid(customer) and customer.customer_sprite:
		Juice.flash_invalid(customer.customer_sprite, Color(1.45, 0.32, 0.32, 1))


func _set_score_text() -> void:
	var label := _resolve_score_label()
	if label == null:
		return
	label.text = str(score)
	label.visible = true
	label.modulate = Color.WHITE


func _update_score() -> void:
	_set_score_text()
	var label := _resolve_score_label()
	if label == null:
		return
	Juice.center_pivot(label)
	Juice.pop_scale(label, 1.14, 0.22)
	var panel := _resolve_score_panel()
	if panel:
		Juice.center_pivot(panel)
		Juice.pop_scale(panel, 1.08, 0.18)


func _finish_customer(slot: int, success: bool = true) -> void:
	if success and slot >= 0 and slot < stands_success_animation.size():
		stands_success_animation[slot].play("move up and fade")
	_clear_slot(slot)
	_queue_spawn(slot, _random_respawn_delay())


func _on_order_part_served(slot: int) -> void:
	var customer := _customers[slot] if slot >= 0 and slot < _customers.size() else null
	_award_points(vip_part_points, customer, false)
	_play_served_sfx()


func _on_served_correct(_order_id: String, slot: int) -> void:
	var customer := _customers[slot] if slot >= 0 and slot < _customers.size() else null
	if customer and customer.is_vip and not customer.is_vip_order_complete():
		return
	var payout := serve_points
	if customer and customer.is_vip:
		payout = vip_finish_points
	_award_points(payout, customer, true)
	_play_served_sfx()
	_play_complete_sfx()
	_finish_customer(slot)


func _on_served_wrong(_order_id: String, _slot: int) -> void:
	if wrong_order_sfx and wrong_order_sfx.stream:
		wrong_order_sfx.play()


func _on_left_angry(_order_id: String, slot: int) -> void:
	var customer := _customers[slot] if slot >= 0 and slot < _customers.size() else null
	_play_angry_meow()
	_apply_penalty(angry_penalty, customer)
	_finish_customer(slot, false)
