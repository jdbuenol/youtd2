extends OptionButton

const HUD_SECTION: String = "hud"
const SELECTED_TOWER: String = "selected_tower"
const SETTINGS_PATH: String = "user://settings.cfg"


func _ready():
	for tower_name in Properties.tower_id_map.keys():
		var tower_id: int = Properties.tower_id_map[tower_name]
		add_item(tower_name, tower_id)
	
	var saved_tower_id: int = _get_saved_tower_id()
	
	if saved_tower_id != -1:
		var saved_tower_index: int = get_item_index(saved_tower_id)
		select(saved_tower_index)


func _get_saved_tower_id() -> int:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var saved_tower_id = config.get_value(Constants.SettingsSection.HUD, Constants.SettingsKey.SELECTED_TOWER)
	
	if saved_tower_id == null:
		return -1
	else:
		return saved_tower_id


func _on_TowerOptionButton_item_selected(_index):
	var config = ConfigFile.new()
	config.set_value(Constants.SettingsSection.HUD, Constants.SettingsKey.SELECTED_TOWER, get_selected_id())
	config.save(SETTINGS_PATH)