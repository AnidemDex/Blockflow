## Modifying values here requires a plugin reload after save.

const PluginConstants = preload("res://addons/blockflow/core/constants.gd")

static func get_default_command_scripts() -> Array:
	var commands := []
	for command_path in PluginConstants.DEFAULT_COMMAND_PATHS:
		if not ResourceLoader.exists(command_path, "Script"):
			push_warning("!ResourceLoader.exists(%s) == true, continuing"%command_path)
			continue
		
		var command_script:Script = load(command_path) as Script
		if not command_script:
			push_warning("CommandList: Resource at '%s' is not an Script."%command_path)
			continue
		commands.append(command_script)
		
	return commands

# TODO: Custom commands made by the user that are not a script/resource file
# and will live under a special folder.
## Commands defined in 
## ProjectSettings [constant PROJECT_SETTING_CUSTOM_COMMANDS]
static func get_custom_commands() -> Array:
	var commands := []
	for command_path in ProjectSettings.get_setting(PluginConstants.PROJECT_SETTING_CUSTOM_COMMANDS, []):
		if not ResourceLoader.exists(command_path):
			push_warning("!ResourceLoader.exists(%s) == true, continuing"%command_path)
			continue
		
		# We can't guess the type, so let's load it as generic 
		# and let the caller handle it.
		var command:Resource = ResourceLoader.load(command_path)
		if not command:
			# HOW?
			push_warning("CommandList: Resource at '%s' is not valid."%command_path)
			continue
		commands.append(command)
		
	return commands

const Debugger = preload("res://addons/blockflow/debugger/debugger_messages.gd")

const Utils = preload("res://addons/blockflow/core/utils.gd")

# Made to ensure that classes are loaded before class_name populates editor
const CollectionClass = preload("res://addons/blockflow/collection.gd")
const CommandCollectionClass = preload("res://addons/blockflow/command_collection.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CommandProcessorClass = preload("res://addons/blockflow/command_processor.gd")
## @deprecated
const TimelineClass = preload("res://addons/blockflow/timeline.gd")

enum Toast {
	SEVERITY_INFO,
	SEVERITY_WARNING,
	SEVERITY_ERROR
	}

class CollectionData:
	var main_collection:CollectionClass
	var command_list:Array[CommandClass]
	var bookmarks:Dictionary

static func generate_tree(collection:CollectionClass) -> CollectionData:
#	if collection.is_updating_data: return
	collection.is_updating_data = true
	
	var data := CollectionData.new()
	
	var command_pt:CommandClass
	
	if collection.is_empty():
		return data
	
	var command_list:Array[CommandClass] = []
	var owner:CollectionClass
	command_pt = collection.collection[0]
	
	for command in collection.collection:
		_recursive_add(command, command_list)
	
	var position:int = 0
	var bookmarks := {}
	for command_position in command_list.size():
		command_pt = command_list[command_position]
		command_pt.position = command_position
		command_pt.weak_collection = weakref(collection as CommandCollectionClass)
		if not command_pt.bookmark.is_empty():
			bookmarks[command_pt.bookmark] = command_pt
	
	data.command_list = command_list
	data.bookmarks = bookmarks
	data.main_collection = collection
	
	if collection is CommandCollectionClass:
		command_list.make_read_only()
		collection._bookmarks = bookmarks
		collection._command_list = command_list
#	collection.set("data", data)
	
	collection.is_updating_data = false
	
	return data

static func _recursive_add(command, to) -> void:
	to.append(command)
	for subcommand in command:
		_recursive_add(subcommand, to)

static func move_to_collection(command, to_collection, to_position=0) -> void:
	var owner_collection = command.get_command_owner()
	owner_collection.erase(command)
	to_collection.insert(command, to_position)
#	var idx = to_position if to_position > -1 else to_collection.collection.size()
#	to_collection.collection.insert(idx, command)
#	owner_collection.emit_changed()
#	to_collection.emit_changed()
#	owner_collection._notify_changed()
#	to_collection._notify_changed()
