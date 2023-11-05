@tool
## Modifying values here requires a plugin reload after save.

const DEFAULT_COMMAND_PATHS = [
	"res://addons/blockflow/commands/command_call.gd",
	"res://addons/blockflow/commands/command_animate.gd",
	"res://addons/blockflow/commands/command_comment.gd",
	"res://addons/blockflow/commands/command_condition.gd",
	"res://addons/blockflow/commands/command_goto.gd",
	"res://addons/blockflow/commands/command_return.gd",
	"res://addons/blockflow/commands/command_set.gd",
	"res://addons/blockflow/commands/command_wait.gd",
	"res://addons/blockflow/commands/command_end.gd",
	]

const PROJECT_SETTING_DEFAULT_COMMANDS =\
"blockflow/settings/commands/default_commands"
const PROJECT_SETTING_CUSTOM_COMMANDS =\
"blockflow/settings/commands/custom_commands"

const PROJECT_SETTING_BLOCK_ICON_MIN_SIZE =\
"blockflow/settings/editor/commands/icon_minimun_size"
const BLOCK_ICON_MIN_SIZE = 32

const Utils = preload("res://addons/blockflow/core/utils.gd")

# Made to ensure that classes are loaded before class_name populates editor
#const CollectionClass = preload("res://addons/blockflow/collection.gd")
#const CommandCollectionClass = preload("res://addons/blockflow/command_collection.gd")
#const CommandClass = preload("res://addons/blockflow/commands/command.gd")

enum Toast {
	SEVERITY_INFO,
	SEVERITY_WARNING,
	SEVERITY_ERROR
	}

class CollectionData:
	var main_collection:Collection
	var command_list:Array[Command]
	var bookmarks:Dictionary

static func generate_tree(collection:Collection) -> CollectionData:
#	if collection.is_updating_data: return
	collection.is_updating_data = true
	
	var data := CollectionData.new()
	
	var command_pt:Command
	
	if collection.is_empty():
		return data
	
	var command_list:Array[Command] = []
	var owner:Collection
	command_pt = collection.collection[0]
	
	for command in collection.collection:
		_recursive_add(command, command_list)
	
	var position:int = 0
	var bookmarks := {}
	for command_position in command_list.size():
		command_pt = command_list[command_position]
		command_pt.position = command_position
		command_pt.weak_collection = weakref(collection as CommandCollection)
	
	data.command_list = command_list
	data.bookmarks = bookmarks
	data.main_collection = collection
	
	collection.set("data", data)
	
	collection.is_updating_data = false
	
	return data

static func _recursive_add(command, to) -> void:
	to.append(command)
	for subcommand in command:
		_recursive_add(subcommand, to)
	
