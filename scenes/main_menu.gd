extends Control

const KITCHEN_SCENE := "res://scenes/demo_kitchen.tscn"

const LOGO_POP_START_SCALE := 1.38
const LOGO_BASE_DURATION := 0.72
const LOGO_LAYER_DURATION := 0.55
const LOGO_LAYER_GAP := 0.12
const BUTTONS_DELAY_AFTER_LOGO := 0.15
const BUTTON_STAGGER := 0.1
const MEOW_PATHS: Array[String] = [
	"res://sounds/sfx/Meows/Meow_01.ogg",
	"res://sounds/sfx/Meows/Meow_02.ogg",
	"res://sounds/sfx/Meows/Meow_03.ogg",
	"res://sounds/sfx/Meows/Meow_04.ogg",
]

@onready var _logo_base: TextureRect = %LogoBase
@onready var _logo_cat: TextureRect = %LogoCat
@onready var _logo_fish: TextureRect = %LogoFishLeft
@onready var _logo_vegi: TextureRect = %LogoVegiRight
@onready var _menu_buttons: Control = %MenuButtons
@onready var _credits_panel: Control = %CreditsPanel
@onready var _credits_content: Control = %CreditsContent

var _meow_player: AudioStreamPlayer


func _ready() -> void:
	_credits_panel.visible = false
	_meow_player = AudioStreamPlayer.new()
	_meow_player.bus = &"Master"
	add_child(_meow_player)
	MusicManager.ensure_main_playing()
	_hide_menu_buttons()
	_prepare_logo_layers()
	call_deferred("_play_menu_intro")


func _prepare_logo_layers() -> void:
	_prepare_hidden_layer(_logo_cat)
	_prepare_hidden_layer(_logo_fish)
	_prepare_hidden_layer(_logo_vegi)
	if _logo_base:
		_logo_base.visible = true
		_logo_base.modulate.a = 0.0
		_logo_base.scale = Vector2.ONE * LOGO_POP_START_SCALE
		Juice.center_pivot(_logo_base)


func _prepare_hidden_layer(layer: TextureRect) -> void:
	if layer == null:
		return
	layer.visible = true
	layer.modulate.a = 0.0
	layer.scale = Vector2.ZERO
	Juice.center_pivot(layer)


func _hide_menu_buttons() -> void:
	if _menu_buttons == null:
		return
	_menu_buttons.visible = true
	_menu_buttons.modulate.a = 0.0
	for child in _menu_buttons.get_children():
		if child is Control:
			var ctrl := child as Control
			ctrl.scale = Vector2.ZERO
			if child is BaseButton:
				(child as BaseButton).disabled = true


func _play_menu_intro() -> void:
	if _logo_base:
		var base_tween := Juice.pop_in_from_overscale(_logo_base, LOGO_POP_START_SCALE, LOGO_BASE_DURATION)
		if base_tween:
			await base_tween.finished

	await get_tree().create_timer(LOGO_LAYER_GAP).timeout
	if _logo_cat:
		var cat_tween := Juice.pop_in_from_overscale(_logo_cat, 1.32, LOGO_LAYER_DURATION)
		if cat_tween:
			await cat_tween.finished
		_play_random_meow()

	await get_tree().create_timer(LOGO_LAYER_GAP * 0.65).timeout
	var fish_tween: Tween = null
	var vegi_tween: Tween = null
	if _logo_fish:
		fish_tween = Juice.pop_in_from_overscale(_logo_fish, 1.28, LOGO_LAYER_DURATION)
	if _logo_vegi:
		vegi_tween = Juice.pop_in_from_overscale(_logo_vegi, 1.28, LOGO_LAYER_DURATION)
	if fish_tween:
		await fish_tween.finished
	if vegi_tween:
		await vegi_tween.finished

	await get_tree().create_timer(BUTTONS_DELAY_AFTER_LOGO).timeout
	_reveal_menu_buttons()


func _play_random_meow() -> void:
	if _meow_player == null:
		return
	var path := MEOW_PATHS[randi() % MEOW_PATHS.size()]
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_meow_player.stream = stream
	_meow_player.play()


func _reveal_menu_buttons() -> void:
	if _menu_buttons == null:
		return
	var fade := create_tween()
	fade.tween_property(_menu_buttons, "modulate:a", 1.0, 0.25)
	var index := 0
	for child in _menu_buttons.get_children():
		if child is Control:
			var ctrl := child as Control
			Juice.center_pivot(ctrl)
			var delay := index * BUTTON_STAGGER
			var pop := create_tween()
			pop.tween_interval(delay)
			pop.tween_property(ctrl, "scale", Vector2.ONE, 0.42)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if child is BaseButton:
				pop.tween_callback((child as BaseButton).set_disabled.bind(false))
			index += 1


func _on_play_pressed() -> void:
	UiSfx.play_click()
	get_tree().change_scene_to_file(KITCHEN_SCENE)


func _on_credits_pressed() -> void:
	UiSfx.play_click()
	MusicManager.play_credits()
	_menu_buttons.visible = false
	_credits_panel.visible = true
	if _credits_content:
		Juice.center_pivot(_credits_content)
		Juice.elastic_pop_in(_credits_content, KitchenLayout.JUICE_SPRING_DURATION)


func _on_credits_back_pressed() -> void:
	UiSfx.play_click()
	MusicManager.stop_credits()
	_credits_panel.visible = false
	_menu_buttons.visible = true
	_menu_buttons.modulate.a = 1.0
	for child in _menu_buttons.get_children():
		if child is Control:
			(child as Control).scale = Vector2.ONE
			if child is BaseButton:
				(child as BaseButton).disabled = false


func _on_exit_pressed() -> void:
	UiSfx.play_click()
	get_tree().quit()
