extends Control


signal start_wave(wave_index)
signal stop_wave()

onready var element_buttons_parent = $MarginContainer/HBoxContainer


func _ready():
	for element_button in element_buttons_parent.get_children():
		element_button.connect("pressed", self, "_on_element_button_pressed", [element_button])
	
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")


func _on_Camera_camera_moved(_direction):
	$Hints.hide()


func _on_Camera_camera_zoomed(_zoom_value):
	$Hints.hide()


func _on_RightMenuBar_tower_info_requested(tower_id):
	var tower = TowerManager.get_tower(tower_id)
	
	$TowerTooltip.set_tower_tooltip_text(tower)
	$TowerTooltip.hide()
	
	$TooltipHeader.set_header_unit(tower)
	$TooltipHeader.show()


func _on_RightMenuBar_tower_info_canceled():
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_MobYSort_child_entered_tree(node):
	if node is Tower:
		node.connect("selected", self, "_on_Tower_selected", [node])
		node.connect("unselected", self, "_on_Tower_unselected")


func _on_Tower_selected(tower_node):
	$TowerTooltip.set_tower_tooltip_text(tower_node)
	$TowerTooltip.hide()
	
	$TooltipHeader.set_header_unit(tower_node)
	$TooltipHeader.show()


func _on_Tower_unselected():
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_BuildingMenuButton_pressed():
	$Hints2.hide()

func _on_ItemMenuButton_pressed():
	$Hints2.hide()

func _on_element_button_pressed(element_button):
	$MarginContainer.hide()
	
	var element: int = element_button.element
	$RightMenuBar.set_element(element)


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
	else:
		$TowerTooltip.hide()
