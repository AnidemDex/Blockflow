@tool
extends "res://addons/blockflow/collection.gd"
class_name CommandCollection

##
## This resource only keeps an ordered reference of all commands registered on it.
##

var _bookmarks:Dictionary = {}
var _command_list:Array = []
var _branches:Array = []
var _subcommads:Array = []

func get_command(position:int) -> Command:
	if position >= _command_list.size():
		push_error("position >= _command_list.size()")
		return null
	return _command_list[position]

## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark:StringName) -> Resource:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Returns the command position in the timeline.
func get_command_absolute_position(command) -> int:
	return _command_list.find(command)

func get_command_count() -> int:
	return _command_list.size()

func is_branch(command:Command) -> bool:
	return command in _branches

func is_subcommand(command:Command) -> bool:
	return command in _subcommads

## Forces an update to contained data.
## [br]This makes all the contained data:
## [br]- Update their index.
## [br]- Update their bookmars.
## [br]- Update their owners.
## [br]- Update their structure.
func update() -> void:
	_notify_changed()

var _index:int
func _update_data(from_collection:Array):
	if from_collection.is_empty(): return
	
	for command in from_collection:
		_command_list.append(command)
		command.index = _index
		_index += 1
		# branches goes first
		if command.branches:
			_update_data(command.branches.collection)
			_branches.append_array(command.branches.collection)
		
		if command.commands:
			_update_data(command.commands.collection)
			_subcommads.append_array(command.commands.collection)
		
		if not command.bookmark.is_empty():
			_bookmarks[command.bookmark] = command
		
		command.weak_collection = weakref(self)


var _updating_data:bool = false
func _notify_changed() -> void:
	if _updating_data: return
	_updating_data = true
	_index = 0
	_command_list = []
	_update_data(collection)
	_updating_data = false
	emit_changed()

#func _get_iterator_ref() -> Array: return _command_list
