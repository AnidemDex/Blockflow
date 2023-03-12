@tool
extends Resource
class_name Command

## Base class for all commands.
##
## Every command relies on this class. 
## If you want to do your own event, you should [code]extend[/code] from this class.
##

signal command_started
signal command_finished

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
