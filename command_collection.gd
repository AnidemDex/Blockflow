@tool
extends "res://addons/blockflow/collection.gd"
class_name CommandCollection

##
## This resource only keeps an ordered reference of all commands registered on it.
##

var data:Blockflow.CollectionData:
	set(value):
		if value == null:
			value = Blockflow.CollectionData.new()
		data = value
		_bookmarks = data.bookmarks
		_command_list = data.command_list

var _bookmarks:Dictionary = {}
var _command_list:Array = []

func get_command(position:int) -> Blockflow.CommandClass:
	if position >= _command_list.size():
		push_error("position >= _command_list.size()")
		return null
	return _command_list[position]

## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark:StringName) -> Blockflow.CommandClass:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Returns the command position in the internal collection
func get_command_absolute_position(command) -> int:
	return _command_list.find(command)

func get_command_count() -> int:
	return _command_list.size()


## Forces an update to contained data.
## [br]This makes all the contained data:
## [br]- Update their index.
## [br]- Update their bookmars.
## [br]- Update their owners.
## [br]- Update their structure.
func update() -> void:
	_notify_changed()

func _set_collection(value:Array) -> void:
	for command in collection:
		command.weak_owner = null
	
	collection = value.duplicate()
	
	for command_index in collection.size():
		var command:Blockflow.CommandClass = collection[command_index]
		command.weak_owner = weakref(self)
		command.weak_collection = weakref(self)
		command.index = command_index
		command.notification(NOTIFICATION_UPDATE_STRUCTURE)
	
#	if not Engine.is_editor_hint():
#		collection.make_read_only()
	
	_notify_changed()

#func _get_iterator_ref() -> Array: return _command_list
