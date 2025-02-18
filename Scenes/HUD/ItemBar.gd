extends GridContainer


# Dictionary of buttons that are currently on the item bar
@onready var _item_buttons: Dictionary = {}


var current_element: Tower.Element
var current_size: String
var _moved_item_button: ItemButton = null


func add_item_button(item_id):
	var item_button: ItemButton = _create_ItemButton(item_id)
	add_child(item_button)
	_item_buttons[item_id] = item_button
	_adjust_size()


func remove_item_button(item_id):
	var item_button: ItemButton = _item_buttons[item_id]
	_item_buttons.erase(item_id)
	item_button.queue_free()
	_adjust_size()


func _ready():
	_resize_icons("S")
	current_size = "S"

	if FF.add_test_item():
		var test_item_list: Array[int] = [77, 78, 79, 99, 105, 108, 155, 158, 159, 218, 231, 244, 249, 268, 274, 1001]

		for item in test_item_list:
			add_item_button(item)

	ItemMovement.item_move_from_itembar_done.connect(on_item_move_from_itembar_done)
	ItemMovement.item_moved_to_itembar.connect(on_item_moved_to_itembar)
	EventBus.item_drop_picked_up.connect(_on_item_drop_picked_up)


func on_item_moved_to_itembar(item_id: int):
	add_item_button(item_id)


func on_item_move_from_itembar_done(move_success: bool):
	if _moved_item_button == null:
		return

	if move_success:
		var item_id: int = _moved_item_button.get_item()
		_item_buttons.erase(item_id)
		_moved_item_button.queue_free()
	else:
#		Disable button to gray it out to indicate that it's
#		getting moved
		_moved_item_button.set_disabled(false)

	_moved_item_button = null

# Disable resize for icons in the RightMenuBar
#func _adjust_size():
#	if current_size == "M":
#		if _item_buttons.size() > 14:
#			_resize_icons("S")
#		else:
#			_resize_icons("M")
#	elif current_size == "S":
#		if _item_buttons.size() > 14:
#			_resize_icons("S")
#		else:
#			_resize_icons("M")
func _adjust_size():
	_resize_icons("S")

func _create_ItemButton(item_id) -> ItemButton:
	var item_button = ItemButton.new()
	item_button.set_item(item_id)
	item_button.button_down.connect(_on_item_button_pressed.bind(item_button))
	return item_button


func _on_item_drop_picked_up(item_id: int):
	add_item_button(item_id)


func _on_item_button_pressed(item_button: ItemButton):
	var item_id: int = item_button.get_item()
	ItemMovement.start_move_from_itembar(item_id)
	_moved_item_button = item_button
	item_button.set_disabled(true)
	item_button.set_pressed_no_signal(true)


func _on_Item_used(item_id):
	remove_item_button(item_id)


func _resize_icons(icon_size: String):
	current_size = icon_size
	if icon_size == "M":
		columns = 2
	else:
		columns = 4
	for item_id in _item_buttons.keys():
		_item_buttons[item_id].set_icon_size(icon_size)


func _on_right_menu_bar_test_signal():
	pass # Replace with function body.
