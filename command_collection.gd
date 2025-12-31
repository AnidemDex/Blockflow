@tool
extends "res://addons/blockflow/collection.gd"
class_name CommandCollection

##
## This resource only keeps an ordered reference of all commands registered on it.
##

var _bookmarks: Dictionary = {}
var _command_list: Array = []

## Get command at [param position]. This takes in consideration all commands
## in internal collection ([member Command.position] instead of [member Command.index])
func get_command(position: int):
	if position >= _command_list.size():
		push_error("position >= _command_list.size()")
		return null
	return _command_list[position]

## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark: StringName) -> Resource:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Returns the command position in the internal collection
func get_command_absolute_position(command) -> int:
	return _command_list.find(command)

## Returns the command total count that this collection (and any internal collection) has.
func get_command_count() -> int:
	return _command_list.size()


## Forces an update to contained data.
## [br]This makes all the contained data:
## [br]- Update their index.
## [br]- Update their bookmars.
## [br]- Update their owners.
## [br]- Update their structure.
func update() -> void:
	rebuild_tree()
	_notify_changed()

func rebuild_tree() -> void:
	if is_updating_data: return
	is_updating_data = true
	
	var new_command_list: Array[Resource] = []
	var new_bookmarks: Dictionary = {}
	
	if not collection.is_empty():
		for command in collection:
			_recursive_build(command, new_command_list)
	
	for command_position in new_command_list.size():
		var command = new_command_list[command_position]
		command.position = command_position
		command.weak_collection = weakref(self)
		
		if not command.bookmark.is_empty():
			new_bookmarks[command.bookmark] = command
	
	_command_list = new_command_list
	_bookmarks = new_bookmarks
	
	is_updating_data = false

func _recursive_build(command: Resource, to_list: Array[Resource]) -> void:
	to_list.append(command)
	for subcommand in command.collection:
		_recursive_build(subcommand, to_list)


func _set_collection(value: Array) -> void:
	for command in collection:
		command.weak_owner = null
	
	collection = value.duplicate()
	
#	if not Engine.is_editor_hint():
#		collection.make_read_only()
	
	_notify_changed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		for command_index in collection.size():
			var command: Resource = collection[command_index]
			command.weak_owner = weakref(self)
			command.weak_collection = weakref(self)
			command.index = command_index
			command.notification(NOTIFICATION_UPDATE_STRUCTURE)
