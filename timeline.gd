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
		
		commands = value
		
		if commands:
			commands.changed.connect(_notify_changed)
		_notify_changed()
	get:
		return commands

var _bookmarks:Dictionary


## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark:StringName) -> Resource:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Returns the command position in the timeline.
func get_command_idx(command) -> int:
	return commands.find(command)

func has(value:Command) -> bool:
	return commands.has(value)

func update_bookmarks() -> void:
	for command in commands:
		if not command.bookmark.is_empty():
			_bookmarks[command.bookmark] = command

func update_indexes() -> void:
	# This probably will cause performance issues
	for command_idx in commands.size():
		commands[command_idx].index = command_idx

func _notify_changed() -> void:
	update_bookmarks()
	update_indexes()
	emit_changed()

func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"commands", "type":TYPE_OBJECT, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE})
	return p
