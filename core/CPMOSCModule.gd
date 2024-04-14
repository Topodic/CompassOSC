## A base class for handling and processing OSC messages from CPM.
## Intended to be extended.
class_name CPMOSCModule
extends Node

## A name for display in the module list.
@export var module_name := "New Module"
## A description for display in the module list.
@export_multiline var module_description := "This is a new CPM OSC Module."
## A module version number. Optional, but nice to have for distribution clarity
## and load priority if an older version is present in the user's folder.
@export var module_version := 0
@export var module_author := "Author Name"
## A unique identifier for this module, used for saving settings.
@export var module_id := "author.modulename"
## A namespace for this module's messages. Must start with /, but can otherwise be anything. (Even just / is OK.)
@export var module_namespace := "/module"
## A link to your module's git repository, if available. (Optional)
@export var module_git_repo := ""
## Set this if your module has persistent data. This will generate a config file
## in the user's data for Compass with a filename based on your module ID.
@export var has_config := false
var config : ConfigFile = null

## This module's controls, if any. Added to the control list when loaded.
var control : ModuleControlBase = null

var _client : OSCClient = null
var _manager : CPMOSCManager = null
var _initialized : bool = false
var _disabled : bool = false

func _init():
	add_to_group("modules")
	if !module_namespace.begins_with("/"):
		printerr("Invalid module namespace: " + module_namespace + "\nNamespaces must begin with /.")

func initialize(client : OSCClient, manager : CPMOSCManager):
	_client = client
	_manager = manager
	manager.message_received.connect(on_message_received)
	_initialized = true
	for child in get_children():
		if child is ModuleControlBase:
			control = child
			control.initialize(self)
	if has_config:
		config = ConfigFile.new()
		var err = config.load("user://" + module_id + ".cfg")
		if err == OK:
			return
		config.save("user://" + module_id + ".cfg")

# Sends a message via OSC client. Will be sent as /module_namespace/address
func send_message(address, arguments):
	assert(_initialized,
	"Module is not initialized. Ensure it's part of the \"modules\" node group.")
	assert(_client != null,
	"OSC client in module is null. Ensure initialization has occurred.")
	
	var final_address = ""
	if module_namespace == "/":
		final_address = module_namespace + address
	else:
		final_address = module_namespace + "/" + address
	_client.send_message(final_address, arguments)

## Listener for Manager's "message_received" signal. Override this in your
## own module to receive and respond to them - changing this won't work when
## exported.
func on_message_received(address, arguments):
	pass

## Virtual method for handling module disabling, called when disabled via Loaded Modules.
func on_disabled():
	pass

## Virtual method for handling module enabling, called when enabled via Loaded Modules.
func on_enabled():
	pass

# A check for whether or not this module has any controls.
func has_controls() -> bool:
	return control != null

func save_configs():
	if config:
		config.save("user://" + module_id + ".cfg")



func set_enabled(enabled : bool = true):
	if enabled:
		set_process(true)
		set_physics_process(true)
		if !_manager.message_received.is_connected(on_message_received):
			_manager.message_received.connect(on_message_received)
		if control:
			control.modulate.a = 1.0
		_disabled = false
	else:
		set_process(false)
		set_physics_process(false)
		if _manager.message_received.is_connected(on_message_received):
			_manager.message_received.disconnect(on_message_received)
		if control:
			control.modulate.a = 0.5
		_disabled = true
		
