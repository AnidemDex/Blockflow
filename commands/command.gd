@tool
extends Resource
class_name Command

## Base class for all commands.
##
## Every command relies on this class. 
## If you want to do your own command, you should [code]extend[/code] from this class.
##

signal command_started
signal command_finished

## Current command position in the timeline.
var index:int

func get_command_name() -> String:
	return _get_command_name()

func get_command_icon() -> Texture:
	return _get_command_icon()

## 
func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	assert(false, "_get_command_name()")
	return "UNKNOW_COMMAND"

func _get_command_icon() -> Texture:
	return null

func _execute() -> void:
	assert(false, "_execute")

func _to_string() -> String:
	return "<Command[%s]#%s>" % [get_command_name(),get_instance_id()]

func _init() -> void:
	resource_local_to_scene = true
