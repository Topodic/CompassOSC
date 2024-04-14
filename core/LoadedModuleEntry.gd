extends PanelContainer

signal module_toggled(toggled)

@onready var module_name_label : RichTextLabel = get_node("MarginContainer/VBoxContainer/HBoxContainer/ModuleNameLabel")
@onready var module_description_label : RichTextLabel = get_node("MarginContainer/VBoxContainer/ModuleDescription")
@onready var module_enabled_check : CheckBox = get_node("MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/EnabledCheck")

func _ready():
	module_enabled_check.toggled.connect(func(toggled): module_toggled.emit(toggled))

func set_git_repo(url : String):
	module_name_label.text = module_name_label.text.replace("Module Name",
		"[color=light_blue][url=" + url + "]Module Name[/url][/color]")
	module_name_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

func set_module_name(name : String):
	module_name_label.text = module_name_label.text.replace("Module Name", name)

func set_module_version(version : int):
	module_name_label.text = module_name_label.text.replace("v0", "v" + str(version))

func set_author_name(name : String):
	module_name_label.text = module_name_label.text.replace("Author Name", name)

func set_description(description : String):
	module_description_label.text = description
