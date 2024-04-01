extends ModuleControlBase

@onready var yes_no_label = $HBoxContainer/YesNoLabel

func post_initialize():
	module.active_changed.connect(_on_active_changed)

func set_no():
	yes_no_label.text = "Don't think so."

func set_yes():
	yes_no_label.text = "Sure is!"


func _on_active_changed(active):
	if active:
		set_yes()
	else:
		set_no()
