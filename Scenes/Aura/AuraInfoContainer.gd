extends Node

# AuraInfoContainer stores the aura info list. It is used by
# ProximitySpell and ProjectileSpell. Aura info is the
# description of an aura, which is used to make the actual
# aura instance. This container handles aura's modifying
# other aura's.

# Aura modifying another aura is implemented like this:
# 
# 1. A tower applies an aura to another the tower.
# 2. The affected tower calls apply_aura() on it's AuraInfoContainer.
# 3. AuraInfoContainer remembers the modifier from given aura.
# 4. Affected tower needs to pass it's aura info list to a projectile.
# 5. Affected tower calls get_modded() on it's AuraInfoContainer.
# 6. get_modded() returns the aura info list with modifiers applied.
# 7. Projectile stores the modified aura info list.
# 8. Projectile reaches the mob and passes modified aura info list to the mob.
# 9. Mob creates aura's based on the modified aura info list.

class_name AuraInfoContainer


var default_aura_info_list: Array

var mod_map: Dictionary = {
	Properties.AuraType.MODIFY_VALUE_FOR_DAMAGE_AURA: 0.0,
	Properties.AuraType.MODIFY_DURATION_FOR_POISON_AURA: 0.0
}


func _init(default_aura_info_list_arg: Array):
	default_aura_info_list = default_aura_info_list_arg


func _ready():
	pass


func apply_aura(aura: Aura):
	if mod_map.has(aura.type):
		if aura.is_expired:
			mod_map[aura.type] = 0.0
		else:
			mod_map[aura.type] = aura.get_value()


# Returns aura info list with all mods applied
# NOTE: have to be careful not to modify default aura list, so use duplicate()
func get_modded() -> Array:
	var modded_aura_info_list: Array = default_aura_info_list.duplicate(true)

	for aura_info in modded_aura_info_list:
		var type: int = aura_info[Properties.AuraParameter.TYPE]
		var duration: int = aura_info[Properties.AuraParameter.DURATION]
		var period: int = aura_info[Properties.AuraParameter.PERIOD]
		var is_damage_aura = type == Properties.AuraType.DAMAGE
		var is_poison_aura = type == Properties.AuraType.DAMAGE && duration > 0 && period > 0

		if is_damage_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + mod_map[Properties.AuraType.MODIFY_VALUE_FOR_DAMAGE_AURA])
		
		if is_poison_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.DURATION, 1.0 + mod_map[Properties.AuraType.MODIFY_DURATION_FOR_POISON_AURA])


	return modded_aura_info_list


func modify_aura_info_value(aura_info: Dictionary, value_key: int, mod_value: float):
	if aura_info[value_key] is Array:
		var modded_value_range: Array = (aura_info[value_key] as Array).duplicate(true)
		
		for value in modded_value_range:
			value *= mod_value

		aura_info[value_key] = modded_value_range
	else:
		aura_info[value_key] *= mod_value