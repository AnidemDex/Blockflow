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
var _command_data:Dictionary = {}

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

## Return -1 if the position doesn't exist or there's no
## possible next command position.
func get_next_command_position_according(position:int) -> int:
	if position >= get_command_count():
		return -1
	if position + 1 >= get_command_count():
		return -1
	
	var command:Command = get_command(position)
	var next_position = position + 1
	if command.can_hold_commads and not command.commands.is_empty():
		next_position = command.commands.get_command(0).index
		return next_position
	
	# Oh mother of all ducks, I really need another
	# way of doing branches
	var next_command:Command = get_command(position + 1)
	while is_instance_of(next_command, Command.Branch):
		next_position = \
		_command_data[next_command.get_command_owner()]["total_branch_count"] + 1
		if next_position < get_command_count():
			next_command = get_command(next_position)
		else:
			next_command = null
			next_position = -1
			break
		
	return next_position


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
	
	_bookmarks.clear()
	for command in from_collection:
		_update_command_data(command)
		
		if not command.bookmark.is_empty():
			_bookmarks[command.bookmark] = command
		
		command.weak_collection = weakref(self)

func _update_command_data(command:Command) -> void:
	_command_data[command] = {}
	_command_list.append(command)
	command.index = _index
	_index += 1
	
	# See this trick here? 
	# I hate it
	# and you will
	var owner:Command = command.get_command_owner()
	if owner:
		var i = 0
		var top_owner
		# What we try is to count, from bottom
		# how far are we from our top-most branch creator
		while owner != null:
			if owner:
				top_owner = owner
				if owner.has_branches():
					_command_data[owner]["total_branch_count"] += 1
			i += 1
			owner = owner.get_command_owner()
		
	
	if not command.bookmark.is_empty():
		_bookmarks[command.bookmark] = command
	
	# Branches goes first
	if command.branches:
		_command_data[command]["total_branch_count"] = 0
		for branch in command.branches:
			_update_command_data(branch)
	
	if command.commands:
		for subcommand in command.commands:
			_update_command_data(subcommand)


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
