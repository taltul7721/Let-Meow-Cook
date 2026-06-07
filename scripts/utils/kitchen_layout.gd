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
const CUSTOMER_BUBBLE_SIZE := Vector2(140, 109)
const CUSTOMER_BUBBLE_OFFSET := Vector2(30, -58)

## Customer feet anchors — move CustomerStand1/2/3 in demo_kitchen.tscn (pink markers in editor).
const CUSTOMER_STAND := Vector2(548.0, 332.0)

const CUSTOMER_SPAWN_FALLBACK := CUSTOMER_STAND

## Black cat sprite (native 260×320).
const CAT_DISPLAY_SIZE := Vector2(130, 160)

const FRIDGE_FISH_SIZE := Vector2(96, 64)
const CUSTOMER_BUBBLE_FOOD_SIZE := Vector2(56, 36)
const CUSTOMER_BUBBLE_ITEM_PADDING := 15

const BOARD_GHOST_SIZE := Vector2(100, 66)
const BOARD_PROCESSING_SIZE := Vector2(100, 66)
const GRILL_PROCESSING_SIZE := Vector2(100, 66)
const STATION_PICKUP_SIZE := Vector2(100, 66)

const PLATE_DISPLAY_SIZE := Vector2(110, 60)
const PLATE_FOOD_SIZE := Vector2(72, 48)
const PLATE_FOOD_Y_OFFSET := 0.0
## Progress bar art is 350×30 px. Height = width × (30 / 350) ≈ width × 0.0857.
## Bubble: 112×10 | Station: 128×11 | Full native: 350×30

const BOARD_GHOST_ALPHA := 0.4
const PLATE_GHOST_ALPHA := 0.45
const JUICE_SPRING_DURATION := 0.35
