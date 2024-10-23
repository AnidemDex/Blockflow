@tool
extends Resource
## CommandRecord
##
## Object in charge of keep track of the registered commands
## used by editor.

## Emmited when [commands] is modified.
signal command_list_changed

const Constants = preload("res://addons/blockflow/core/constants.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

## Path to a record file. Made as property and not constant just in case
## user defines its own record
var RECORD_PATH = "res://addons/blockflow/core/command_record.tres"

## Registered and tracked commands. 
## A duplicated array is returned when you get this value.
var commands:Array:
	get: return _commands.duplicate()

# Registered and tracked commands
var _commands:Array = []:
	set(value):
		if _is_main_record():
			_commands = value
			emit_changed()
		
	get:
		if _is_main_record():
			return _commands
		return get_record()._commands

# <script>: [commands] <- 1:many
var _scripts:Dictionary = {}:
	set(value):
		if _is_main_record():
			_scripts = value
			emit_changed()
	get:
		if _is_main_record():
			return _scripts
		return get_record()._scripts

# "resource_path": command <- 1:1
var _paths:Dictionary = {}:
	set(value):
		if _is_main_record():
			_paths = value
			emit_changed()
	get:
		if _is_main_record():
			return _paths
		return get_record()._paths

# Little flag to prevent recursion in case we're
# playing with project settings here.
var _updating:bool = false

## Get the command record "singleton".
func get_record():
	if resource_path.is_empty():
		return weakref(load(RECORD_PATH)).get_ref()
	
	return weakref(self).get_ref()

## Add a command to record.
## [param command_data] can be [Script], [Command] or a path.
func register(command_data:Variant, update_project_settings:bool = true) -> void:
	var command:CommandClass
	var command_path:String
	var command_script:Script
	
	if typeof(command_data) == TYPE_STRING:
		command_path = command_data
		if not ResourceLoader.exists(command_path):
			push_error(
				"CommandRecord: Can't load resource at '%s'" % command_path
				)
			return
		
		if command_path in _paths:
			# There's already a command registered at that path.
			return
		
		command_data = load(command_path)
	
	if command_data is Script:
		command_script = command_data
		command_path = command_data.resource_path
		if command_script in _scripts:
			# Already registered?
			return
		
		if command_path.is_empty():
			push_error("CommandRecord: Can't register scripts with empty path.")
			return
		
		if command_path.is_valid_filename():
			push_error("CommandRecord: Can't register script with invalid path.")
			return
		
		command_data = command_script.new()
		
	if command_data is CommandClass:
		command = command_data
		if command in _commands:
			# Already registered?
			return
	else:
		push_error("CommandRecord: %s is not a valid type" % command_data )
		return
	
	_updating = true
	
	# Register in commands
	_commands.append(command)
	
	# Validate and register in scripts
	if not command_script:
		command_script = command.get_script()
	
	if not command_script in _scripts:
		var scripts:Array = _scripts.get(command_script, [])
		scripts.append(command)
		_scripts[command_script] = scripts
	
	if not command in _scripts[command_script]:
		_scripts[command_script].append(command)
	
	if command_path.is_empty():
		command_path = command.resource_path
	
	if not command_path in _paths:
		_paths[command_path] = command
	
	if update_project_settings:
		var custom_command_paths:PackedStringArray =\
		ProjectSettings.get_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS, PackedStringArray())
		custom_command_paths.append(command_path)
		ProjectSettings.set_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS, custom_command_paths)
		if Engine.is_editor_hint():
			var error := ProjectSettings.save()
			if error:
				push_error("CommandRecord: %s while saving ProjectSettings" % error_string(error))
	
	notify_record_changed()
	
	_updating = false

## Removes the command from record
func unregister(command_data:Variant) -> void:
	var command:CommandClass
	var command_path:String
	var command_script:Script
	
	if command_data is Script:
		command_script = command_data
		
		_updating = true
		
		for c in _scripts.get(command_script, []):
			command = c
			command_path = command.resource_path
			_commands.erase(command)
			_paths.erase(command_path)
		
		_scripts.erase(command_script)
		
		notify_record_changed()
		
		_updating = false
		return
	
	
	if typeof(command_data) == TYPE_STRING:
		command_path = command_data
		command = _paths.get(command_path)
		command_script = command.get_script()
	
	if command_data is CommandClass:
		command = command_data
		command_path = command.resource_path
		command_script = command.get_script()
	
	_updating = true
	
	_commands.erase(command)
	_paths.erase(command_path)
	_scripts.get(command_script, []).erase(command)
	
	notify_record_changed()
	
	_updating = false


func reload_from_project_settings(add_plugin_commands:bool = false) -> void:
	if _updating:
		return
	
	if not ProjectSettings.has_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS):
		# No settings to load?
		return
	
	var new_paths:PackedStringArray = ProjectSettings.get_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS, [])
	new_paths.sort()
	
	var old_paths := PackedStringArray(_paths.keys())
	old_paths.sort()
	
	if  old_paths == new_paths:
		# Same paths, probably, no need to update anything.
		return
	
	_commands.clear()
	_scripts.clear()
	_paths.clear()
	
	if add_plugin_commands:
		_register_default_commands()
	
	for path in new_paths:
		_updating = true
		register(path, false)
		_updating = false


func notify_record_changed() -> void:
	command_list_changed.emit()
	get_record().command_list_changed.emit()


func _register_default_commands() -> void:
	for command_path in Constants.DEFAULT_COMMAND_PATHS:
		_updating = true
		register(command_path, false)
		_updating = false

func _is_main_record() -> bool:
	return get_record() == self


func _init() -> void:
	if not Engine.is_editor_hint():
		return
	
	if not ProjectSettings.has_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS):
		ProjectSettings.set_setting(Constants.PROJECT_SETTING_CUSTOM_COMMANDS, PackedStringArray())
		var setting_info:Dictionary = {
			"name": Constants.PROJECT_SETTING_CUSTOM_COMMANDS,
			"type": TYPE_PACKED_STRING_ARRAY,
			"hint": PROPERTY_HINT_FILE, # TODO: Find a way to show a file selector
			"hint_string": "*.gd"
		}
		ProjectSettings.add_property_info(setting_info)
		var error:= ProjectSettings.save()
		if error:
			push_error("CommandRecord: Failed saving settings %s" % error_string(error))
