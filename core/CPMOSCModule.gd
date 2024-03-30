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

var _client : OSCClient = null
var _initialized : bool = false

func _init():
	add_to_group("modules")
	if !module_namespace.begins_with("/"):
		printerr("Invalid module namespace: " + module_namespace + "\nNamespaces must begin with /.")

func initialize(client : OSCClient, manager : CPMOSCManager):
	_client = client
	manager.message_received.connect(on_message_received)
	_initialized = true

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

# Listener for Manager's "message_received" signal.
func on_message_received(address, arguments):
	pass
