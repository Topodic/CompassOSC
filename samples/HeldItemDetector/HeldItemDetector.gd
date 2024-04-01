extends CPMOSCModule

signal active_changed(active)

var currently_active = false:
	set(val):
		currently_active = val
		active_changed.emit(currently_active)

func on_message_received(address, argument):
	match address:
		"/cpm/held_item/id":
			var id = argument[0]
			if id == "minecraft:redstone_block" and !currently_active:
				currently_active = true
				# This will affect an animation called
				# osc:/sample/holding_redstone_block(0.0:1.0)
				send_message("holding_redstone_block", true)
			elif id != "minecraft:redstone_block" and currently_active:
				currently_active = false
				send_message("holding_redstone_block", false)
