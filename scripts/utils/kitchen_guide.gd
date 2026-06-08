class_name KitchenGuide
extends RefCounted
## Derives the one-line player hint from kitchen + order state.


static func hint_for(
	has_selection: bool,
	selected_state: String,
	customer: Customer,
	fridge_bubble_open: bool,
	board_busy: bool,
	grill_busy: bool,
	plate_has_food: bool,
	plate_food_state: String,
	has_empty_plate: bool = true
) -> String:
	if customer == null or not customer.is_active():
		return "A customer will arrive soon…"

	var order := customer.order_id

	if not has_selection and not fridge_bubble_open:
		return _fridge_hint_for_order(order)

	if not has_selection and fridge_bubble_open:
		
		return "Take the fish from the fridge bubble."

	match selected_state:
		"raw":
			if board_busy:
				return "Wait for the fish to finish chopping."
			return "Place the whole fish on the cutting board."
		"cut":
			if order == "sushi":
				if plate_has_food:
					return "Select a plate, then click the customer."
				if not has_empty_plate:
					return "Both plates are full — serve a dish first."
				return "Put the cut fish on an empty plate."
			if grill_busy:
				return "Wait for the grill to finish."
			if not has_empty_plate:
				return "Both plates are full — serve a dish first."
			if plate_has_food and plate_food_state == "cut":
				return "Grill the cut fish first, then plate it."
			return "Grill the cut fish, then move it to a plate."
		"cooked":
			if plate_has_food:
				return "Select a plate, then click the customer."
			if not has_empty_plate:
				return "Both plates are full — serve a dish first."
			return "Put the grilled fish on an empty plate, then serve."
		_:
			return "Follow the order in the speech bubble."


static func recipe_subtitle(order_id: String) -> String:
	match order_id:
		"sushi":
			return "Fridge -> Chop -> Plate"
		"cooked_fish":
			return "Fridge -> Chop -> Grill -> Plate"
		_:
			return ""


static func _fridge_hint_for_order(order: String) -> String:
	match order:
		"sushi":
			return "Tap the fridge to get fish — sushi needs chopping only."
		"cooked_fish":
			return "Tap the fridge to get fish — then chop and grill."
		_:
			return "Tap the fridge to start cooking."
