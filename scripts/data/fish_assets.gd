class_name FishAssets
extends RefCounted
## Single swap point for all fish / plate dish art. Replace PATH_* when cute assets are ready.

const PATH_RAW := "res://assets/sprite/dish/fish.png"
const PATH_CUT := "res://assets/sprite/dish/cutted_fish.png"
const PATH_COOKED := "res://assets/sprite/dish/cutted_fish_cooked.png"
const PATH_PLATE := "res://assets/sprite/dish/plate.png"

static var _raw: Texture2D
static var _cut: Texture2D
static var _cooked: Texture2D
static var _plate: Texture2D


static func raw() -> Texture2D:
	if _raw == null:
		_raw = load(PATH_RAW) as Texture2D
	return _raw


static func cut() -> Texture2D:
	if _cut == null:
		_cut = load(PATH_CUT) as Texture2D
	return _cut


static func cooked() -> Texture2D:
	if _cooked == null:
		_cooked = load(PATH_COOKED) as Texture2D
	return _cooked


static func plate() -> Texture2D:
	if _plate == null:
		_plate = load(PATH_PLATE) as Texture2D
	return _plate


static func for_state(state: String) -> Texture2D:
	match state:
		"raw":
			return raw()
		"cut":
			return cut()
		"cooked":
			return cooked()
		_:
			return null


static func for_order(order_id: String) -> Texture2D:
	match order_id:
		"sushi":
			return cut()
		"cooked_fish":
			return cooked()
		_:
			return null


static func board_processing() -> Texture2D:
	return raw()


static func grill_processing() -> Texture2D:
	return cut()
