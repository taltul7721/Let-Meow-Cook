extends Node

@export var atlas_coordinates : Dictionary[String, Vector2]

func _ready() -> void:
	GameManager.selection_changed.connect(on_selection_changed)
	GameManager.selection_cleared.connect(on_selection_cleared)
	$RunTimer.time_expired.connect(on_time_expired)
	
func on_selection_changed(source : Node) -> void:
	if (source is SelectableSource):
		var selectable_source = source as SelectableSource
		var item_state = selectable_source.item_state
		var item_id = selectable_source.item_id
		
		if item_state == "raw" and %BoardDrop.can_accept(selectable_source.get_item_data()):
			var board_ghost : TextureRect = %BoardGhostGuide
			(board_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
			board_ghost.visible = true
		else:
			%BoardGhostGuide.visible = false
		if item_state == "cut":
			if %GrillDrop.can_accept(selectable_source.get_item_data()):
				var grill_ghost : TextureRect = %GrillGhostGuide
				(grill_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
				grill_ghost.visible = true
			else:
				%GrillGhostGuide.visible = false
			if %Plate1.can_accept(selectable_source.get_item_data()):
				var grill_ghost : TextureRect = %PlateGhostGuide
				(grill_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
				grill_ghost.visible = true
			else:
				%PlateGhostGuide.visible = false
			if %Plate2.can_accept(selectable_source.get_item_data()):
				var grill_ghost : TextureRect = %PlateGhostGuide2
				(grill_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
				grill_ghost.visible = true
			else:
				%PlateGhostGuide2.visible = false
		if item_state == "cooked":
			if %Plate1.can_accept(selectable_source.get_item_data()):
				var grill_ghost : TextureRect = %PlateGhostGuide
				(grill_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
				grill_ghost.visible = true
			else:
				%PlateGhostGuide.visible = false
			if %Plate2.can_accept(selectable_source.get_item_data()):
				var grill_ghost : TextureRect = %PlateGhostGuide2
				(grill_ghost.texture as AtlasTexture).region.position = atlas_coordinates[item_id + " " + item_state]
				grill_ghost.visible = true
			else:
				%PlateGhostGuide2.visible = false

func on_selection_cleared() -> void:
	%BoardGhostGuide.visible = false
	%GrillGhostGuide.visible = false
	%PlateGhostGuide.visible = false
	%PlateGhostGuide2.visible = false
	
func on_time_expired() -> void:
	get_tree().paused = true
