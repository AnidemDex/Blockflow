@tool
extends Resource
class_name Timeline
##
## Base class for all Timelines
##
## Deprecated. Legacy class.
## This resource only keeps an ordered reference of all commands registered on it.
##

var commands:Array[Command]:
	set(value):
		commands = value
		_notify_changed()
	get:
		return commands

var _bookmarks:Dictionary


## Adds a [Command] to the timeline
func add_command(command:Command) -> void:
	if has(command):
		push_error("add_command: Trying to add an command to the timeline, but the command is already added")
		return
	commands.append(command)
	_notify_changed()

## Insert an [code]Command[/code] at position.
func insert_command(command:Command, at_position:int) -> void:
	if has(command):
		push_error("insert_command: Trying to add an command to the timeline, but the command already exist")
		return
	
	var idx = at_position if at_position > -1 else commands.size()
	commands.insert(idx, command)
	
	_notify_changed()

## Duplicates a [Command] to the timeline
func duplicate_command(command:Command, to_position:int) -> void:
	var duplicated = command.duplicate()
	var idx = to_position if to_position > -1 else commands.size()
	commands.insert(idx, duplicated)
	
	_notify_changed()

## Moves an [code]command[/code] to position.
func move_command(command, to_position:int) -> void:
	if !has(command):
		push_error("move_command: Trying to move an command in the timeline, but the command is not added.")
		return
	
	var old_position:int = get_command_idx(command)
	if old_position < 0:
		return
	
	to_position = to_position if to_position > -1 else commands.size()
	if to_position == old_position:
		emit_changed()
		return
	
	commands.remove_at(old_position)
	
	if to_position < 0 or to_position > commands.size():
		to_position = commands.size()
	
	commands.insert(to_position, command)
	
	_notify_changed()
	notify_property_list_changed()

## Get the command at [code]position[/code]
func get_command(position:int) -> Resource:
	if position < commands.size():
		return commands[position]
	
	push_error("get_command: Tried to get an command on a non-existing position: ", position)
	return null

## Get the command [code]position[/code] from its [code]bookmark[/code]
func get_command_by_bookmark(bookmark:StringName) -> Resource:
	if not bookmark in _bookmarks:
		push_error("get_command_by_bookmark: Couldn't find command with a bookmark: ", bookmark)
	
	return _bookmarks.get(bookmark, null)

## Removes an command from the timeline.
func erase_command(command) -> void:
	commands.erase(command)
	_notify_changed()

## Removes an command at [code]position[/code] from the timelin
func remove_command(position:int) -> void:
	commands.remove_at(position)
	_notify_changed()

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

func get_collection_equivalent() -> CommandCollection:
	var collection := CommandCollection.new()
	collection.collection = commands.duplicate()
	return collection
			

func _notify_changed() -> void:
	update_bookmarks()
	update_indexes()
	emit_changed()
	pass

func _init() -> void:
	push_warning(
"""[%s]Timeline: This class is deprecated and will be removed in
future versions.
Consider using CommandCollection class."""%resource_path
	)

func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"commands", "type":TYPE_ARRAY, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE})
	return p
