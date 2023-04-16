@tool
extends Command

@export var method:String
@export var args:Array

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "Call"


func _get_hint() -> String:
	return method + "()"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/function.svg")
