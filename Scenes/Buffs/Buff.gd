class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active.


class EventHandler:
	var callable: Callable
	var chance: float
	var chance_level_add: float


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new()
var _level: int
var _power: int
var _time: float
var _friendly: bool
var _type: String
var _stacking_group: String
var _timer: Timer
# Map of Event.Type -> list of EventHandler's
var event_handler_map: Dictionary = {}
# Used by aura's to know when to remove buff that was
# applied by aura.
var _applied_by_aura_count: int = 0
var _original_duration: float = 0.0
var _cleanup_complete: bool = false
var _tooltip_text: String
var _buff_icon: String
var _purgable: bool


# NOTE: buff type determines what happens when a buff is
# applied while the target already has active buffs. If buff
# type is empty, then buff will always be applied. If buff
# type is set to something, then buff will be applied only
# if the target doesn't already have an active buff with
# same type. If new buff has higher lever than current
# active buff, then current active buff is upgraded and
# refreshed.
# func _init(type: String, time_base: float, time_level_add: float, friendly: bool):
# 	_type = type
# 	_time_base = time_base
# 	_time_level_add = time_level_add
# 	_friendly = friendly

func _ready():
#	NOTE: fix "unused" warning
	_applied_by_aura_count = _applied_by_aura_count

	if _time > 0.0:
		_timer = Timer.new()
		add_child(_timer)
		_timer.timeout.connect(_on_timer_timeout)

		var buff_duration_mod: float = _caster.get_prop_buff_duration()
		var debuff_duration_mod: float = _target.get_prop_debuff_duration()

		var total_time: float = _time * buff_duration_mod

		if !_friendly:
			total_time *= debuff_duration_mod

		_timer.start(total_time)
		_original_duration = total_time

	_target.death.connect(_on_target_death)
	_target.kill.connect(_on_target_kill)
	_target.level_up.connect(_on_target_level_up)
	_target.attack.connect(_on_target_attack)
	_target.attacked.connect(_on_target_attacked)
	_target.dealt_damage.connect(_on_target_dealt_damage)
	_target.damaged.connect(_on_target_damaged)
	_target.spell_casted.connect(_on_target_spell_casted)
	_target.spell_targeted.connect(_on_target_spell_targeted)

	var create_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CREATE, create_event)


func is_friendly() -> bool:
	return _friendly


func refresh_duration():
	set_remaining_duration(_original_duration)


func set_remaining_duration(duration: float):
	if _timer != null:
		_timer.start(duration)


func is_purgable() -> bool:
	return _purgable


func get_buff_icon() -> String:
	return _buff_icon


# NOTE: if no tooltip text is defined, return type name to
# at least make it possible to identify the buff
func get_tooltip_text() -> String:
	if !_tooltip_text.is_empty():
		return _tooltip_text
	else:
		return _type


func get_modifier() -> Modifier:
	return _modifier


# Level is used to compare this buff with another buff of
# same type that is active on target and determine which
# buff is stronger. Stronger buff will end up remaining
# active on the target.
func get_level() -> int:
	return _level


# Power level is used to calculate the total time and total
# value of modifiers.
func get_power() -> int:
	return _power


func get_type() -> String:
	return _type


func get_stacking_group() -> String:
	return _stacking_group


func get_caster() -> Unit:
	return _caster


func get_buffed_unit() -> Unit:
	return _target


func remove_buff():
	var cleanup_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)

	_target._remove_buff_internal(self)


func purge_buff():
	var purge_event: Event = _make_buff_event(null)
	_call_event_handler_list(Event.Type.PURGE, purge_event)

	remove_buff()


func _add_event_handler(event_type: Event.Type, callable: Callable, chance: float, chance_level_add: float):
	var handler: EventHandler = EventHandler.new()
	handler.callable = callable
	handler.chance = chance
	handler.chance_level_add = chance_level_add

	var handler_node: Node = callable.get_object() as Node

	if !handler_node.tree_exiting.is_connected(_on_handler_node_tree_exiting):
		handler_node.tree_exiting.connect(_on_handler_node_tree_exiting)

	_add_event_handler_internal(event_type, handler)


func _add_event_handler_internal(event_type: Event.Type, handler: EventHandler):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _add_periodic_event(callable: Callable, period: float):
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_periodic_event_timer_timeout.bind(callable, timer))


func _add_event_handler_unit_comes_in_range(callable: Callable, radius: float, target_type: TargetType):
	var buff_range_area_scene: PackedScene = load("res://Scenes/Buffs/BuffRangeArea.tscn")
	var buff_range_area = buff_range_area_scene.instantiate()
	add_child(buff_range_area)
	buff_range_area.init(radius, target_type, callable)

	buff_range_area.unit_came_in_range.connect(_on_unit_came_in_range)


func _on_unit_came_in_range(callable: Callable, unit: Unit):
	var range_event: Event = _make_buff_event(unit)

	callable.call(range_event)


# NOTE: do not call event handlers after cleanup event.
# Otherwise it would be possible to trigger cleanup twice by
# killing a creep inside cleanup handler for example.
func _call_event_handler_list(event_type: Event.Type, event: Event):
	if !event_handler_map.has(event_type):
		return

	if _cleanup_complete:
		return

	if event_type == Event.Type.CLEANUP:
		_cleanup_complete = true

	event._buff = self

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		var caster_level: int = _caster.get_level()
		var total_chance: float = handler.chance + handler.chance_level_add * (1 - caster_level)
		var chance_success: bool = _caster.calc_chance(total_chance)

		if !chance_success:
			continue

		var callable: Callable = handler.callable
		callable.call(event)


func _on_timer_timeout():
	var expire_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)

	remove_buff()


func _on_target_death(death_event: Event):
	death_event._buff = self
	_call_event_handler_list(Event.Type.DEATH, death_event)

	var cleanup_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)


# NOTE: this will get called when the object that applied
# this buff is removed from the game. For example, if a
# tower casted a slow on creeps and that tower gets sold,
# then the debuff will get removed. Another example is if an
# item applied a buff and was moved from tower to storage.
# In such cases, the buff *must* be removed because without
# the object which implements event handlers, the buff
# cannot continue operating in a correct manner.
func _on_handler_node_tree_exiting():
	remove_buff()


func _on_target_kill(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.KILL, event)


func _on_target_level_up():
	var event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.LEVEL_UP, event)


func _on_target_attack(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACK, event)


func _on_target_attacked(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACKED, event)


func _on_target_dealt_damage(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGE, event)


func _on_target_damaged(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGED, event)


func _on_target_spell_casted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_CAST, event)


func _on_target_spell_targeted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_TARGET, event)


func _on_periodic_event_timer_timeout(callable: Callable, timer: Timer):
	var periodic_event: Event = _make_buff_event(_target)
	periodic_event._timer = timer
	callable.call(periodic_event)


# Convenience function to make an event with "_buff" variable set to self
func _make_buff_event(target_arg: Unit) -> Event:
	var event: Event = Event.new(target_arg)
	event._buff = self

	return event


func _upgrade_or_refresh(new_level: int):
	var current_level: int = get_level()

	if current_level > new_level:
		refresh_duration()
		
		_level = new_level
		_target._change_modifier_level(get_modifier(), current_level, new_level)

		var upgrade_event: Event = _make_buff_event(_target)
		_call_event_handler_list(Event.Type.UPGRADE, upgrade_event)
	elif current_level == new_level:
		refresh_duration()

		var refresh_event: Event = _make_buff_event(_target)
		_call_event_handler_list(Event.Type.REFRESH, refresh_event)


func _add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(get_caster())
	add_child(aura)
