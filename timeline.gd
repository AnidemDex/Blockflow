extends Resource
class_name Timeline

##
## Base class for all Timelines
##
## This resource only keeps an ordered reference of all commands registered on it.
##

var commands:Array[Command]:
	set(value):
		commands = value
		emit_changed()
	get:
		return commands

## Adds a [Command] to the timeline
func add_command(command:Command) -> void:
	if has(command):
		push_error("add_command: Trying to add an command to the timeline, but the command is already added")
		return
	commands.append(command)
	emit_changed()

## Insert an [code]Command[/code] at position.
func insert_command(command:Command, at_position:int) -> void:
	if has(command):
		push_error("insert_command: Trying to add an command to the timeline, but the command already exist")
		return
	
	var idx = at_position if at_position > -1 else commands.size()
	commands.insert(idx, command)
	
	emit_changed()


func has(value:Command) -> bool:
	return commands.has(value)


func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"_commands", "type":TYPE_ARRAY, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE})
	return p
