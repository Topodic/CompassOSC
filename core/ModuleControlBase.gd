## A very general base class for module controls. Useless if not extended.
class_name ModuleControlBase
extends PanelContainer

## An array of paths to [i]relevant[/i] control nodes, ie sliders or input fields.
@export var control_nodepaths : Array[NodePath] = []
## A dictionary of the actual controls linked to by the above.
var controls = {}
## This control's respective module
var module = null

func initialize(module : CPMOSCModule):
	self.module = module 

func _ready():
	for path in control_nodepaths:
		if !path:
			continue
		var node = get_node(path)
		controls[node.name] = node
