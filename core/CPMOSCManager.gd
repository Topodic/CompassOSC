## This class serves to process messages received via OSC and relay them 
## to modules for processing and response.
class_name CPMOSCManager
extends Node

signal message_received(address, arguments)

@onready var _server : OSCServer = $OSCServer
@onready var _client : OSCClient = $OSCClient 

@onready var _incoming_messages : Dictionary = _server.incoming_messages 
@onready var _modules : Array = get_tree().get_nodes_in_group("modules")

@onready var _controls_list = get_node("PanelContainer/MarginContainer/TabContainer/Controls/ScrollContainer/ModuleControlList")

var current_game_time = 0
var current_tick_rate = 0

var _process_time = 0.0
var _ticks = 0

func _ready():
	_client.message_sent.connect(_on_message_sent)
	load_packed_modules()
	for module in _modules:
		assert(module is CPMOSCModule, "Invalid node found in module list: " + str(module))
		module.initialize(_client, self)
		if module.has_controls():
			module.control.reparent(_controls_list)
			module.control.show()
	

func _process(delta):
	_process_time += delta
	if _process_time >= 1.0:
		current_tick_rate = _ticks
		_process_time = 0.0
		_ticks = 0

	# Necessary check, due to tickrate leaving the dictionary bare at launch
	if _incoming_messages.has("/cpm/gameTime"):
		var _game_time = _incoming_messages["/cpm/gameTime"][0]
		if current_game_time != _game_time:
			_ticks += 1
			current_game_time = _game_time
			for key in _incoming_messages.keys():
				message_received.emit(key, _incoming_messages[key])

	pass

func _on_message_sent(address, arguments):
	print("Outgoing Message: ", address, " ", arguments)

func load_packed_modules():
	var dir = DirAccess.open("res://modules/")
	dir.list_dir_begin()
	var file = dir.get_next()
	var module_name = file.rstrip(".pck").split("_")[0].split("-")[0]

	while file:
		var success = ProjectSettings.load_resource_pack("res://modules/" + file)
		if success:
			var module = load("res://modules/" + module_name + "/" + module_name + ".tscn")
			if module == null:
				printerr("Error loading module: " + module_name)
			else:
				module = module.instantiate()
				var module_exists = false
				for existing_module in _modules:
					if existing_module.module_id == module.module_id:
						if existing_module.module_version < module.module_version:
							print(module.module_name + "(" + module.module_id + ")" + " is already present, but older than this version. Loading new version.")
							_modules.erase(existing_module)
							existing_module.remove_from_group("modules")
							existing_module.queue_free()
						else:
							print(module.module_name + "(" + module.module_id + ")" + " is already loaded.")
							module_exists = true

				if !module_exists and module != null:
					print(module.module_name + " loaded!")
					add_child(module)
					_modules.append(module)
				else:
					module.queue_free()
			
		file = dir.get_next()
		module_name = file.rstrip(".pck")
