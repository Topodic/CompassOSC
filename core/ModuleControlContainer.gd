extends PanelContainer

@onready var vbox = $MarginContainer/VBoxContainer
@onready var label = $MarginContainer/VBoxContainer/Header/ModuleNameLabel
@onready var toggle = $MarginContainer/VBoxContainer/Header/ToggleButton

func _ready():
	toggle.toggled.connect(_on_toggled)

func attach_control(control : ModuleControlBase):
	if control.get_parent():
		control.reparent(vbox)
	else:
		vbox.add_child(control)
	label.text = control.module.module_name

func _on_toggled(toggled : bool):
	for child in vbox.get_children():
		if child.name == "Header":
			continue
		child.visible = toggled
