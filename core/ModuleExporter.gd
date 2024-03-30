extends Control

# Don't worry, I know how slipshod this script is. If it works it works, right?

@onready var _godot_executable_button : Button = get_node("PanelContainer/MarginContainer/MainVBox/ExecutableContainer/FileSelect/FileSelectorButton")
@onready var _godot_executable_line : LineEdit = get_node("PanelContainer/MarginContainer/MainVBox/ExecutableContainer/FileSelect/FilePath")
@onready var _module_project_button : Button = get_node("PanelContainer/MarginContainer/MainVBox/ProjectContainer/FileSelect/FileSelectorButton")
@onready var _module_project_line : LineEdit = get_node("PanelContainer/MarginContainer/MainVBox/ProjectContainer/FileSelect/FilePath")
@onready var _save_to_button : Button = get_node("PanelContainer/MarginContainer/MainVBox/SaveContainer/FileSelect/FileSelectorButton")
@onready var _save_to_line : LineEdit = get_node("PanelContainer/MarginContainer/MainVBox/SaveContainer/FileSelect/FilePath")
@onready var _export_button : Button = get_node("PanelContainer/MarginContainer/MainVBox/HBoxContainer/ExportButton")

@onready var _godot_executable_selection : FileDialog = get_node("ExecutableSelect")
@onready var _module_project_selection : FileDialog = get_node("ProjectSelect")
@onready var _save_to_selection : FileDialog = get_node("SaveSelect")

@onready var _config = ConfigFile.new()
@onready var _export_config = ConfigFile.new()

var _exporting = false

func _ready():
	get_tree().root.size = Vector2(800, 600)
	get_tree().root.unresizable = true
	
	_godot_executable_button.pressed.connect(_executable_select_button_pressed)
	_godot_executable_selection.file_selected.connect(_executable_file_selected)
	
	_module_project_button.pressed.connect(_module_project_button_pressed)
	_module_project_selection.dir_selected.connect(_module_project_selected)
	
	_save_to_button.pressed.connect(_save_to_button_pressed)
	_save_to_selection.file_selected.connect(_save_to_selected)
	
	_export_button.pressed.connect(_export_button_pressed)
	
	
	var err = _config.load("user://config.cfg")
	if err != OK:
		match err:
			ERR_FILE_NOT_FOUND:
				print("Generating new config file.")
				_config.set_value("Export", "Executable Path", "")
				_config.save("user://config.cfg")
			_:
				printerr("Unknown error trying to load config.")
	else:
		_godot_executable_line.text = _config.get_value("Export", "Executable Path")

	err = _export_config.load("res://export_presets.cfg")
	assert(err == OK)
	_export_config.set_value("preset.0", "export_files", PackedStringArray())
	_export_config.save("res://export_presets.cfg")

func _process(_delta):
	_export_button.disabled = _exporting or (_godot_executable_line.text == "") or (_module_project_line.text == "") or (_save_to_line.text == "")

func _executable_select_button_pressed():
	_godot_executable_selection.popup()

func _module_project_button_pressed():
	_module_project_selection.popup()

func _save_to_button_pressed():
	_save_to_selection.popup()

func _export_button_pressed():
	var dir = _module_project_line.text
	var binary = _godot_executable_line.text
	var out = _save_to_line.text
	var project_directory = DirAccess.open(dir)
	project_directory.list_dir_begin()
	
	var files = PackedStringArray()
	var file = project_directory.get_next()
	while file:
		files.append(dir + "/" + file)
		file = project_directory.get_next()
	_export_config.set_value("preset.0", "export_files", files)
	_export_config.save("res://export_presets.cfg")

	_exporting = true
	_godot_executable_button.disabled = true
	_save_to_button.disabled = true
	_module_project_button.disabled = true
	var _result = []
	OS.execute(binary, PackedStringArray(["--headless", "--export-pack", "Module", out]), _result)
	print(_result)
	
	_exporting = false
	_godot_executable_button.disabled = false
	_save_to_button.disabled = false
	_module_project_button.disabled = false


func _executable_file_selected(file : String):
	var output = []
	OS.execute(file, ["--help"], output)
	var line = output[0].split("\r")[0]
	line = output[0]
	var valid_binary = line.contains("Godot") and line.contains("v4")
	if !valid_binary:
		printerr("File is not a valid Godot v4.x binary.")
		return
	_godot_executable_line.text = file
	_config.set_value("Export", "Executable Path", file)
	_config.save("user://config.cfg")

func _module_project_selected(directory : String):
	_module_project_line.text = directory

func _save_to_selected(file : String):
	if !file.ends_with(".pck"):
		file += ".pck"
	_save_to_line.text = file
