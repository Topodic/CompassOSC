extends CPMOSCModule

signal active_changed(active)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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
				send_message("holding_redstone_block", true)
			elif id != "minecraft:redstone_block" and currently_active:
				currently_active = false
				send_message("holding_redstone_block", false)
