## This class serves to process messages received via OSC and relay them 
## to modules for processing and response. (You don't need to mess with this.)
class_name CPMOSCManager
extends Node

signal message_received(address, arguments)

@onready var _server : OSCServer = $OSCServer
@onready var _client : OSCClient = $OSCClient 

@onready var _incoming_messages : Dictionary = _server.incoming_messages 
@onready var _loaded_modules : Array = get_tree().get_nodes_in_group("modules")
var _module_filepaths : Array = []

@onready var _controls_list = %ModuleControlList
@onready var _loaded_modules_list = %LoadedModulesList

@onready var _ip_address_entry = %IPAddress
@onready var _receiving_port_entry = %ReceivingPort
@onready var _sending_port_entry = %SendingPort

@onready var _info_toggle = %InfoToggle
@onready var _debug_toggle = %DebugToggle
@onready var _warning_toggle = %WarningToggle
@onready var _error_toggle = %ErrorToggle
@onready var _incoming_toggle = %IncomingToggle
@onready var _outgoing_toggle = %OutgoingToggle

var _control_container = preload("res://core/ModuleControlContainer.tscn")
var _loaded_module_entry = preload("res://core/LoadedModuleEntry.tscn")

var _config = ConfigFile.new()

var current_game_time = 0
var current_tick_rate = 0

var _process_time = 0.0
var _ticks = 0

func _ready():
	DisplayServer.window_set_min_size(Vector2i(500, 350))
	
	var err = _config.load("user://manager.cfg")
	if !err == OK:
		_config.set_value("Network", "IPAddress", "127.0.0.1")
		_config.set_value("Network", "ReceivingPort", 9001)
		_config.set_value("Network", "SendingPort", 9000)
		_config.set_value("Logging", "Info", true)
		_config.set_value("Logging", "Debug", false)
		_config.set_value("Logging", "Warning", false)
		_config.set_value("Logging", "Error", true)
		_config.set_value("Logging", "Incoming", false)
		_config.set_value("Logging", "Outgoing", false)
		_config.save("user://manager.cfg")
		
	
	# Set networking values.
	var ip_address = _config.get_value("Network", "IPAddress")
	var receiving = _config.get_value("Network", "ReceivingPort")
	var sending = _config.get_value("Network", "SendingPort")
	
	_client.ip_address = ip_address
	_client.port = sending
	_client.connect_socket(ip_address, sending)
	_ip_address_entry.text = ip_address
	_sending_port_entry.value = sending

	_server.port = receiving
	_server.listen(receiving)
	_receiving_port_entry.value = receiving
	
	# Set Logging options.
	var _info = _config.get_value("Logging", "Info")
	var _debug = _config.get_value("Logging", "Debug")
	var _warning = _config.get_value("Logging", "Warning")
	var _error = _config.get_value("Logging", "Error")
	var _incoming = _config.get_value("Logging", "Incoming")
	var _outgoing = _config.get_value("Logging", "Outgoing")
	
	Logging.set_level(Logging.MessageLevel.INFO, _info)
	Logging.set_level(Logging.MessageLevel.DEBUG, _debug)
	Logging.set_level(Logging.MessageLevel.WARNING, _warning)
	Logging.set_level(Logging.MessageLevel.ERROR, _error)
	Logging.set_level(Logging.MessageLevel.INCOMING, _incoming)
	Logging.set_level(Logging.MessageLevel.OUTGOING, _outgoing)
	
	_info_toggle.button_pressed = _info
	_debug_toggle.button_pressed = _debug
	_warning_toggle.button_pressed = _warning
	_error_toggle.button_pressed = _error
	_incoming_toggle.button_pressed = _incoming
	_outgoing_toggle.button_pressed = _outgoing
	
	# Connect signals.
	message_received.connect(_on_message_received)
	_client.message_sent.connect(_on_message_sent)
	
	_ip_address_entry.text_submitted.connect(_ip_address_changed)
	_receiving_port_entry.value_changed.connect(_receiving_port_changed)
	_sending_port_entry.value_changed.connect(_sending_port_changed)
	
	_info_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.INFO))
	_debug_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.DEBUG))
	_warning_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.WARNING))
	_error_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.ERROR))
	_incoming_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.INCOMING))
	_outgoing_toggle.toggled.connect(_logging_toggle_changed.bind(Logging.MessageLevel.OUTGOING))
	
	# Workaround for a quirk with DirAccess and loading resource packs
	# in Godot itself, see https://github.com/godotengine/godot/issues/87274
	import_modules()
	if import_pcks():
		import_modules()

	for module in _loaded_modules:
		assert(module is CPMOSCModule, "Invalid node found in module list: " + str(module))
		module.initialize(_client, self)
		
		attach_module_controls(module)
		add_loaded_modules_entry(module)


func _ip_address_changed(address : String):
	_client.connect_socket(address, _client.port)

func _receiving_port_changed(port : int):
	_server.listen(port)

func _sending_port_changed(port : int):
	_client.connect_socket(_client.ip_address, port)

func _logging_toggle_changed(toggled : bool, level : Logging.MessageLevel):
	Logging.set_level(level, toggled)
	var key = Logging.level_to_string(level).capitalize()
	_config.set_value("Logging", key, toggled)
	_config.save("user://manager.cfg")

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

func _on_message_received(address, arguments):
	Logging.write(address + ": " + str(arguments), Logging.MessageLevel.INCOMING)
	
func _on_message_sent(address, arguments):
	Logging.write(address + ": " + str(arguments), Logging.MessageLevel.OUTGOING)

func import_pcks() -> bool:
	var dir = DirAccess.open("res://modules")
	var err = DirAccess.get_open_error()
	if err == ERR_INVALID_PARAMETER:
		DirAccess.make_dir_absolute("res://modules")
		return false
	
	var paths = []
	_recurse_for_pcks(paths, dir)
	for pck in paths:
		ProjectSettings.load_resource_pack(pck, false)
		
	return true

func import_modules():
	var dir = DirAccess.open("res://modules")
	var err = DirAccess.get_open_error()
	if err == ERR_INVALID_PARAMETER:
		DirAccess.make_dir_absolute("res://modules")
		return false
	
	var modules : Array[CPMOSCModule] = []
	_recurse_for_modules(modules, dir)
	for module in modules:
		var module_exists = false
		for existing_module in _loaded_modules:
			if existing_module.module_id == module.module_id:
				if existing_module.module_version < module.module_version:
					Logging.write(module.module_name + "(" + module.module_id + ")" + " is already present, but older than this version. Loading new version.", Logging.MessageLevel.INFO)
					_loaded_modules.erase(existing_module)
					existing_module.remove_from_group("modules")
					existing_module.queue_free()
				else:
					Logging.write(module.module_name + "(" + module.module_id + ")" + " is already loaded.")
					module_exists = true

		if !module_exists:
			add_child(module)
			Logging.write(module.module_name + " (" + module.module_id + ")" + " loaded!", Logging.MessageLevel.INFO)
			_loaded_modules.append(module)
		else:
			module.queue_free()

func attach_module_controls(module : CPMOSCModule):
	if module.has_controls():
		var _container = _control_container.instantiate()
		_controls_list.add_child(_container)
		_container.attach_control(module.control)
		module.control.show()

func add_loaded_modules_entry(module : CPMOSCModule):
	var entry = _loaded_module_entry.instantiate()
	_loaded_modules_list.add_child(entry)
	if module.module_git_repo != "":
		entry.set_git_repo(module.module_git_repo)
	entry.set_module_name(module.module_name)
	entry.set_module_version(module.module_version)
	entry.set_author_name(module.module_author)
	entry.set_description(module.module_description)

func _recurse_for_pcks(paths : Array, dir : DirAccess):
	var dirs = dir.get_directories()
	var files = dir.get_files()
	
	for file in files:
		if file.ends_with(".pck"):
			paths.append(dir.get_current_dir() + "/" + file)

	for subdir in dirs:
		error_string(dir.change_dir(subdir))
		_recurse_for_pcks(paths, dir)
		error_string(dir.change_dir(".."))
		
func _recurse_for_modules(modules : Array[CPMOSCModule], dir : DirAccess):
	var dirs = dir.get_directories()
	var files = dir.get_files()
	
	for file in files:
		var is_scene = file.ends_with(".tscn")
		var is_remap = file.ends_with(".tscn.remap")
		if !is_scene and !is_remap:
			continue
		var scene_path = dir.get_current_dir() + "/" + file.rstrip(".remap")
		var node = load(scene_path).instantiate()
		if node is CPMOSCModule:
			_module_filepaths.append(scene_path)
			modules.append(node)
		else:
			node.free()
	for subdir in dirs:
		dir.change_dir(subdir)
		_recurse_for_modules(modules, dir)
		dir.change_dir("..")

