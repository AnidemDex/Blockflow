@tool
extends Command

@export var behavior:CommandProcessor.ReturnValue = CommandProcessor.ReturnValue.AFTER

func _execution_steps() -> void:
	command_started.emit()
	command_manager.return_to_previous_jump(behavior)


func _get_name() -> StringName:
	return "Return"


func _get_hint() -> String:
	return ("to last timeline" if to_last_timeline else "to last jump") +\
		(" (repeat)" if behavior == 0 else "")


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")
