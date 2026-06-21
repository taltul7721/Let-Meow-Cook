class_name KitchenLayout
extends RefCounted
## Display bounding boxes (pixels) — high-res art scaled with KEEP_ASPECT_CENTERED.

const VIEWPORT_SIZE := Vector2(1152, 648)

## Foreground bar overlay — renders above the cat sprite, below the order bubble.
const PATH_COUNTER_BAR := "res://assets/sprite/BackgroundBar.png"
const PATH_SPEECH_BUBBLE := "res://assets/ui/Speech_Bubble.png"
const PATH_SCORE_UI := "res://assets/ui/Timer.png"
const PATH_TIMER_UI := "res://assets/ui/Timer.png"
const LASER_Z_INDEX := 38
const LASER_WARNING_Z_INDEX := 42
const CUSTOMER_LAYER_Z_INDEX := 5
const CUSTOMER_SPRITE_Z_INDEX := 0
const CUSTOMER_BUBBLE_Z_INDEX := 6
const CUSTOMER_PATIENCE_Z_INDEX := 7
const COUNTER_BAR_Z_INDEX := 10
const CUSTOMER_OVERLAY_Z_INDEX := 12
const CUSTOMER_BUBBLE_SIZE := Vector2(132, 100)
const CUSTOMER_BUBBLE_SIZE_VIP := Vector2(168, 138)
const CUSTOMER_BUBBLE_OFFSET := Vector2(30, -58)
const CUSTOMER_BUBBLE_SLOT_NUDGE := [
	Vector2(-14.0, -66.0),
	Vector2(0.0, -64.0),
	Vector2(14.0, -66.0),
]
const CUSTOMER_BUBBLE_SLOT_NUDGE_VIP := [
	Vector2(0.0, -78.0),
	Vector2(0.0, -80.0),
	Vector2(0.0, -78.0),
]
const VIP_CAT_X_NUDGE := 6.0


static func bubble_offset_for(slot: int, vip: bool, customer_width: float, bubble_width: float) -> Vector2:
	var slot_idx := clampi(slot, 0, 2)
	var nudge: Vector2 = CUSTOMER_BUBBLE_SLOT_NUDGE_VIP[slot_idx] if vip else CUSTOMER_BUBBLE_SLOT_NUDGE[slot_idx]
	var centered_x := (customer_width - bubble_width) * 0.5
	return Vector2(centered_x + nudge.x, nudge.y)

## Customer feet anchors — move CustomerStand1/2/3 in demo_kitchen.tscn (pink markers in editor).
const CUSTOMER_STAND := Vector2(548.0, 332.0)

const CUSTOMER_SPAWN_FALLBACK := CUSTOMER_STAND

## Black cat sprite (native 260×320).
const CAT_DISPLAY_SIZE := Vector2(130, 160)

const FRIDGE_FISH_SIZE := Vector2(96, 64)
const CUSTOMER_BUBBLE_FOOD_SIZE := Vector2(56, 36)
const CUSTOMER_BUBBLE_ITEM_PADDING := 15

const BOARD_GHOST_SIZE := Vector2(88, 58)
const BOARD_GHOST_Y_OFFSET := -12.0
const BOARD_PROCESSING_SIZE := Vector2(88, 58)
const GRILL_GHOST_SIZE := Vector2(88, 58)
const GRILL_GHOST_Y_OFFSET := 0.0
const GRILL_PROCESSING_SIZE := Vector2(88, 58)
const STATION_PICKUP_SIZE := Vector2(88, 58)

const PLATE_DISPLAY_SIZE := Vector2(110, 60)
const PLATE_FOOD_SIZE := Vector2(52, 34)
const PLATE_GHOST_SIZE := PLATE_FOOD_SIZE
const PLATE_FOOD_Y_OFFSET := -3.0
const PLATE_GHOST_Y_OFFSET := PLATE_FOOD_Y_OFFSET
## Progress bar art is 350×30 px. Height = width × (30 / 350) ≈ width × 0.0857.
## Bubble: 112×10 | Station: 128×11 | Full native: 350×30

const BOARD_GHOST_ALPHA := 0.4
const PLATE_GHOST_ALPHA := 0.45
const JUICE_SPRING_DURATION := 0.35
