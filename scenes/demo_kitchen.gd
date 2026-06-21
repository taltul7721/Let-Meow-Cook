extends Node

@export var atlas_coordinates : Dictionary[String, Vector2]

func _ready() -> void:
	GameManager.selection_changed.connect(on_selection_changed)
	GameManager.selection_cleared.connect(on_selection_cleared)
	$RunTimer.time_expired.connect(on_time_expired)
	MusicManager.ensure_main_playing()
	MusicManager.reset_main_pitch()
	if has_node("SFX"):
		MusicManager.boost_sfx_in($SFX)
	if has_node("%HintLabel"):
		%HintLabel.visible = false
	call_deferred("_show_opening_tutorial")


func _show_opening_tutorial() -> void:
	if has_node("%CookTutorial"):
		%CookTutorial.start(_start_gameplay)
	else:
		_start_gameplay()


func _start_gameplay() -> void:
	var run_timer := get_node_or_null("RunTimer")
	if run_timer and run_timer.has_method("start_run"):
		run_timer.start_run()
	if has_node("%CustomerSpawner") and %CustomerSpawner.has_method("start_spawning"):
		%CustomerSpawner.start_spawning()
	var laser := get_node_or_null("LaserHazard")
	if laser and laser.has_method("start_hazard"):
		laser.start_hazard()
	if has_node("%HintLabel"):
		%HintLabel.text = "Read each cat's order — tap the fridge to cook!"
		%HintLabel.visible = true


func _show_board_ghost(item_key: String) -> void:
	var ghost: TextureRect = %BoardGhostGuide
	(ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_key]
	ItemDisplay.layout_ghost_on_anchor(
		ghost,
		%BoardDrop,
		KitchenLayout.BOARD_GHOST_SIZE,
		KitchenLayout.BOARD_GHOST_Y_OFFSET,
		KitchenLayout.BOARD_GHOST_ALPHA
	)
	ghost.visible = true


func _show_grill_ghost(item_key: String) -> void:
	var ghost: TextureRect = %GrillGhostGuide
	(ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_key]
	ItemDisplay.layout_ghost_on_anchor(
		ghost,
		%GrillDrop,
		KitchenLayout.GRILL_GHOST_SIZE,
		KitchenLayout.GRILL_GHOST_Y_OFFSET,
		KitchenLayout.BOARD_GHOST_ALPHA
	)
	ghost.visible = true


func _show_plate_ghost(ghost: TextureRect, plate: Control, item_key: String) -> void:
	(ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_key]
	ItemDisplay.layout_ghost_on_anchor(
		ghost,
		plate,
		KitchenLayout.PLATE_GHOST_SIZE,
		KitchenLayout.PLATE_GHOST_Y_OFFSET,
		KitchenLayout.PLATE_GHOST_ALPHA
	)
	ghost.visible = true


func on_selection_changed(source : Node) -> void:
	if (source is SelectableSource):
		var selectable_source := source as SelectableSource
		var item_state: String = selectable_source.item_state
		var item_id: String = selectable_source.item_id
		var item_key: String = item_id + " " + item_state
		
		if item_state == "raw":
			if %BoardDrop.can_accept(selectable_source.get_item_data()):
				_show_board_ghost(item_key)
			else:
				%BoardGhostGuide.visible = false
			if %GrillDrop.can_accept(selectable_source.get_item_data()):
				_show_grill_ghost(item_key)
			else:
				%GrillGhostGuide.visible = false
		else:
			%BoardGhostGuide.visible = false
			if item_state != "cut" and item_state != "cooked":
				%GrillGhostGuide.visible = false
		if item_state == "cut":
			if %GrillDrop.can_accept(selectable_source.get_item_data()):
				_show_grill_ghost(item_key)
			else:
				%GrillGhostGuide.visible = false
			if %Plate1.can_accept(selectable_source.get_item_data()):
				_show_plate_ghost(%PlateGhostGuide, %Plate1, item_key)
			else:
				%PlateGhostGuide.visible = false
			if %Plate2.can_accept(selectable_source.get_item_data()):
				_show_plate_ghost(%PlateGhostGuide2, %Plate2, item_key)
			else:
				%PlateGhostGuide2.visible = false
		if item_state == "cooked":
			if %Plate1.can_accept(selectable_source.get_item_data()):
				_show_plate_ghost(%PlateGhostGuide, %Plate1, item_key)
			else:
				%PlateGhostGuide.visible = false
			if %Plate2.can_accept(selectable_source.get_item_data()):
				_show_plate_ghost(%PlateGhostGuide2, %Plate2, item_key)
			else:
				%PlateGhostGuide2.visible = false

func on_selection_cleared() -> void:
	%BoardGhostGuide.visible = false
	%GrillGhostGuide.visible = false
	%PlateGhostGuide.visible = false
	%PlateGhostGuide2.visible = false
	
func on_time_expired() -> void:
	var final_score := 0
	if %CustomerSpawner.has_method("get_score"):
		final_score = %CustomerSpawner.get_score()
	%EndCard.show_result(final_score)
