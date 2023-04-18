@tool
extends Command

@export var method:String
@export var args:Array

func _execution_steps() -> void:
	command_started.emit()
	
	if not method.is_empty():
		target_node.callv(method, args)
	
	command_finished.emit()


func _get_name() -> String:
	return "Call"


func _get_hint() -> String:
	return method + "(" + str(args).trim_prefix("[").trim_suffix("]") + ")"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/function.svg")
