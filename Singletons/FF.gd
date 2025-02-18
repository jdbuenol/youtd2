# Feature Flags (FF) node contains methods for enabling/disabling
# certain functionality
extends Node


func fast_waves_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/fast_waves") as bool

func visible_spell_dummys_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/visible_spell_dummys") as bool

func dev_controls_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/dev_controls") as bool

func add_test_item() -> bool:
	return ProjectSettings.get_setting("application/config/add_test_item") as bool

func preload_all_towers_on_startup() -> bool:
	return ProjectSettings.get_setting("application/config/preload_all_towers_on_startup") as bool

func build_version() -> String:
	return ProjectSettings.get_setting("application/config/version") as String

func minimap_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/minimap_enabled") as bool

func damage_numbers() -> bool:
	return ProjectSettings.get_setting("application/config/damage_numbers") as bool

func ignore_requirements() -> bool:
	return ProjectSettings.get_setting("application/config/ignore_requirements") as bool

func sfx_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/sfx_enabled") as bool
