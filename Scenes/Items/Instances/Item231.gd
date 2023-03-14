# Currency Converter
extends Item

# TODO: visual


func _item_init():
	var on_periodic_buff: Buff = TriggersBuff.new()
	on_periodic_buff.add_periodic_event(self, "_on_periodic", 1.0)
	_buff_list.append(on_periodic_buff)


func _on_periodic(event: Event):
	var itm = self

	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	event.enable_advanced(15 - lvl * 0.3, false)
	if tower.get_exp() >= 2.0:
		Utils.sfx_on_unit("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", tower, "head")
		tower.remove_exp_flat(2)
		tower.getOwner().give_gold(7, tower, true, true)
	else:
		Utils.display_floating_text("Not enough credits!", tower, 255, 0, 0)