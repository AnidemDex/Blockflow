@tool
extends Command

enum ReturnValue {BEFORE=-1,NO_RETURN, AFTER}

var returns_to:int = ReturnValue.AFTER

func _execution_steps() -> void:
	command_started.emit()
	command_manager.return_command(returns_to)


func _get_name() -> String:
	return "Return"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")
