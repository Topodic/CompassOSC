# CompassOSC
Modular OSC software built primarily for the Customizable Player Models Minecraft mod. Made with Godot.

---
# Basic Usage
This is currently an early version of this project, so expect to run into bugs I haven't yet encountered. However, for basic usage and module creation, all essentials are in place. The release versions of this software are feature-bare by design, as it is intended to be used in conjunction with modules developed using the project itself. CompassOSC looks for modules in `.pck` format stored in a `modules` directory alongside the executable and will load them at launch. If you don't plan on developing any modules, all you need to do is place the modules you wish to use in that directory and you're good to go.

# Module Development
Creating a module is relatively simple, and an exporting tool is provided to make the process as convenient as possible. To make new modules, you'll need to download the [Godot Engine](https://godotengine.org/download) (any v4.x version should do), clone this repository, and open the project. Currently, the way exported modules are loaded is a little restrictive on how your own module workspace should be organized - you should have a `modules` directory, followed by a directory for your module containing all your scripts and scenes. Your module's main node (the one with a script extending `CPMOSCModule.gd`) must share a name with the folder it's in. Ensure that it looks something like this before exporting:
```
res://
├─ addons/
├─ core/
├─ modules/
│ ├─ MyModuleName/
│ │ ├─ MyModuleName.gd
│ │ ├─ MyModuleName.tscn
│ │ ├─ YourOtherFilesAndScripts.gd
```
More detailed development instructions and sample modules for easier understanding will come at a later time.
## Classes
A couple base classes and scenes are provided for you to extend to ensure everything works smoothly.

### CPMOSCModule
`CPMOSCModule.gd` will be the main class you'll use for any custom modules, and should be extended in a new script rather than edited directly:
```
CPMOSCModule.gd
  class_name CPMOSCModule
  extends Node
---
(module name).gd
  extends CPMOSCModule
```
The node this script is attached to should be a direct child of `CPMOSCManager` and saved to its own scene file, preferably `modules/(module name)/(module name).tscn` as detailed above. Overriding `on_message_received(address, arguments)` gives you access to messages received via OSC, and `send_message(address, arguments)` lets you send messages in turn. Additionally, you can configure details about your module in the inspector with your module's Node selected (**importantly, should be the main scene itself, not while you're in `CPMOSCManager.tscn`**, changes there will *not* be saved to your scene file). Very basic config support is available in the form of `config`. If config is enabled in your module's details, a config file will be generated at runtime for your module to store and read data from, though implementation will be up to you due to the broad nature of modules. To test your module, simply run `CPMOSCManager.tscn` with your main node attached.
### ModuleControlBase
Both this scene and script are provided if you wish to associate any `Control` elements with your module. Similarly to the module itself, you should create an inherited scene from `ModuleControlBase.tscn` (right click > `New Inherited Scene`) and extend the `ModuleControlBase.gd` script on it. Once attached to your module's main node, it will be added to the list in the `Controls` tab for the user to interface with. Data from the controls can be retrieved and handled within your script as you need. 

## Exporting
To export your module for distribution, you first may need to open `Editor > Manage Export Templates...` and install the export templates if you haven't already. After this, run the `ModuleExporter.tscn` scene and follow the instructions to export your module as a `.pck` file, which you or others can then place in `modules` to use in the standalone CompassOSC builds. Note, `Module Project` should be the directory containing your module's files, not the `modules` directory. 

---
### Credits
This software uses a version of Drew Farrar's [GodOSC](https://github.com/afarra6/godosc) plugin modified for compatibility with the messages sent by Customizable Player Models and to tweak a few issues encountered during development.
