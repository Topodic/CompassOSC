## A very general base class for module controls. Useless if not extended.
class_name ModuleControlBase
extends PanelContainer

## An array of paths to [i]relevant[/i] control nodes, ie sliders, input fields, or other ModuleControls.
@export var control_nodepaths : Array[NodePath] = []

## Whether the controls you wish to track will be in a Dictionary or Array.
## Dictionary will be more useful for controls with specific, known names,
## while Arrays will be more useful when you just need an easily-iterable
## list of the controls.
@export_enum("Dictionary", "Array") var control_collection_type = "Dictionary"

## A collection of the actual controls linked to by the above.
var controls = null
## This control's respective module
var module = null

var _initialized = false

func initialize(module : CPMOSCModule):
	self.module = module
	assert("control_collection_type" != null, "Control collection type not set!")

	match control_collection_type:
		"Dictionary":
			controls = {}
		"Array":
			controls = []


	for path in control_nodepaths:
		# Just skip empty paths.
		if !path:
			continue
		var node = get_node(path)
		if node is ModuleControlBase:
			node.initialize(module)
		match control_collection_type:
			"Dictionary":
				controls[node.name] = node
			"Array":
				controls.append(node)
	
	print("Controls connected: " + str(controls))
	_initialized = true
	post_initialize()

func post_initialize():
	pass
