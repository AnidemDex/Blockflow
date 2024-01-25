@tool
extends "res://addons/blockflow/commands/command.gd"
## Return to the previous goto jump

var behavior:Blockflow.CommandProcessorClass.ReturnValue\
 = Blockflow.CommandProcessorClass.ReturnValue.AFTER

func _execution_steps() -> void:
	command_started.emit()
	command_manager.return_to_previous_jump(behavior)


func _get_name() -> StringName:
	return "Return"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")


func _get_category() -> StringName:
	return &"Flow"
