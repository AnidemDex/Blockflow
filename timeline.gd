@tool
extends Resource
class_name Timeline
##
## Base class for all Timelines
##
## This resource only keeps an ordered reference of all commands registered on it.
##

var commands:CommandCollection:
	set(value):
		if commands == value: return # Avoid re-assignation
		if commands:
			if commands.changed.is_connected(_notify_changed):
				commands.changed.disconnect(_notify_changed)
		
		if value == null:
			value = CommandCollection.new()
		
		commands = value
		commands.owner = weakref(self)
		
		if commands:
			commands.changed.connect(_notify_changed)
		_notify_changed()
	get:
		return commands

var _bookmarks:Dictionary = {}
var _command_list:Array = []

func get_command(index:int) -> Command:
	if index >= _command_list.size():
		push_error("index >= _command_list.size()")
		return null
	return _command_list[index]

## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark:StringName) -> Resource:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Returns the command position in the timeline.
func get_command_idx(command) -> int:
	return _command_list.find(command)

func get_command_count() -> int:
	return _command_list.size()

func has(value:Command) -> bool:
	return commands.has(value)

## Forces an update to contained data.
## [br]This makes all the contained data:
## [br]- Update their index.
## [br]- Update their bookmars.
## [br]- Update their owners.
## [br]- Update their structure.
func update() -> void:
	_notify_changed()

var _index:int
func _update_data(from_collection:CommandCollection):
	if not from_collection: return
	
	for command in from_collection:
		_command_list.append(command)
		command.index = _index
		_index += 1
		# branches goes first
		_update_data(command.branches)
		_update_data(command.commands)
		
		if not command.bookmark.is_empty():
			_bookmarks[command.bookmark] = command
		
		command.weak_timeline = weakref(self)

var _updating_data:bool = false
func _notify_changed() -> void:
	if _updating_data: return
	_updating_data = true
	_index = 0
	_command_list = []
	_update_data(commands)
	_updating_data = false
	emit_changed()

func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"commands", "type":TYPE_OBJECT, "usage":PROPERTY_USAGE_NO_EDITOR})
	return p

func _init() -> void:
	commands = CommandCollection.new()
