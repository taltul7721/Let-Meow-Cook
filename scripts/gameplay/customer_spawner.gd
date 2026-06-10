extends Node

@export var spawn_parent : Node
@export var customer_scene: PackedScene
@export var score_label: Label
@export var respawn_delay_min: float = 2.5
@export var respawn_delay_max: float = 7.0
@export var serve_points: int = 50
@export var angry_penalty: int = 5
@export var customer_count: int = 3
@export var initial_spawn_delays: Array[float] = [0.0, 4.0, 9.0]

const STAND_NAMES := ["CustomerStand1", "CustomerStand2", "CustomerStand3"]
const ORDER_OPTIONS := ["sushi", "cooked_fish"]

var score: int = 0
var _customers: Array[Customer] = []

signal customer_spawned(customer: Customer)


func _ready() -> void:
	if customer_scene == null:
		customer_scene = preload("res://scenes/customer.tscn")
	_customers.resize(customer_count)
	call_deferred("_spawn_initial_customers")
	_update_score()


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


func _spawn_initial_customers() -> void:
	for slot in customer_count:
		_schedule_spawn_at_slot(slot, _initial_delay_for_slot(slot))


func _initial_delay_for_slot(slot: int) -> float:
	if slot >= 0 and slot < initial_spawn_delays.size():
		return maxf(initial_spawn_delays[slot], 0.0)
	return float(slot) * 4.5


func _schedule_spawn_at_slot(slot: int, delay: float) -> void:
	if delay <= 0.0:
		_spawn_at_slot(slot)
		return
	await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_spawn_at_slot(slot)


func _spawn_at_slot(slot: int) -> void:
	_clear_slot(slot)

	var parent: Node = _resolve_spawn_parent()
	if parent == null:
		push_error("CustomerSpawner: could not find CustomerLayer.")
		return

	var customer := customer_scene.instantiate() as Customer
	if customer == null:
		push_error("CustomerSpawner: customer_scene must instantiate a Customer.")
		return

	parent.add_child(customer)
	customer.z_index = KitchenLayout.CUSTOMER_LAYER_Z_INDEX
	_place_at_stand(customer, slot)
	customer.visible = true
	customer.show()

	customer.served_correct.connect(_on_served_correct, CONNECT_ONE_SHOT)
	customer.left_angry.connect(_on_left_angry, CONNECT_ONE_SHOT)
	customer.start(_pick_order())
	_customers[slot] = customer
	customer_spawned.emit(customer)


func _place_at_stand(customer: Control, slot: int) -> void:
	var feet := _resolve_feet_position(slot)
	var sz := customer.size
	customer.position = Vector2(feet.x - sz.x * 0.5, feet.y - sz.y)
	if customer.has_method("_layout_cat_sprite"):
		customer.call("_layout_cat_sprite")


func _resolve_feet_position(slot: int) -> Vector2:
	var kitchen := _get_demo_kitchen()
	if kitchen and slot < STAND_NAMES.size():
		var stand := kitchen.get_node_or_null(STAND_NAMES[slot]) as Control
		if stand:
			return stand.position + Vector2(stand.size.x * 0.5, stand.size.y)
	if kitchen and kitchen.has_node("CustomerStand2"):
		var stand := kitchen.get_node("CustomerStand2") as Control
		return stand.position + Vector2(stand.size.x * 0.5, stand.size.y)
	return KitchenLayout.CUSTOMER_STAND


func _resolve_spawn_parent() -> Node:
	return spawn_parent


func _get_demo_kitchen() -> Node:
	var root := get_tree().root if get_tree() else null
	if root == null:
		return null
	return root.get_node_or_null("DemoKitchen")


func _clear_slot(slot: int) -> void:
	if slot < 0 or slot >= _customers.size():
		return
	var customer := _customers[slot]
	if customer == null:
		return
	customer.queue_free()
	_customers[slot] = null


func _active_order_ids() -> Array[String]:
	var orders: Array[String] = []
	for customer in _customers:
		if customer and customer.is_active():
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


func _on_served_correct(_order_id: String) -> void:
	score += serve_points
	_update_score()
	var slot : int = -1
	for i in _customers.size():
		if _customers[i] != null and _customers[i].order_id == _order_id:
			_customers[i] = null
			slot = i
			break
	await get_tree().create_timer(_random_respawn_delay()).timeout
	if is_inside_tree():
		_spawn_at_slot(slot)


func _on_left_angry(slot: int, _order_id: String) -> void:
	score = max(score - angry_penalty, 0)
	_update_score()
	_customers[slot] = null
	await get_tree().create_timer(_random_respawn_delay()).timeout
	if is_inside_tree():
		_spawn_at_slot(slot)


func _update_score() -> void:
	var label := score_label
	if label == null:
		var kitchen := _get_demo_kitchen()
		if kitchen:
			label = kitchen.get_node_or_null("ScorePanel/ScoreValue") as Label
	if label:
		label.text = str(score)
