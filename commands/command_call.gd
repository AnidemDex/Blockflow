@tool
extends "res://addons/blockflow/commands/command.gd"

@export var method:String:
	set(value):
		method = value
		emit_changed()
	get:
		return method
@export var args:Array:
	set(value):
		args = value
		emit_changed()
	get:
		return args

func _execution_steps() -> void:
	command_started.emit()
	
	if not method.is_empty():
		target_node.callv(method, args)
	
	command_finished.emit()


func _get_name() -> StringName:
	return "Call"


func _get_hint() -> String:
	var hint_str = method + "(" + str(args).trim_prefix("[").trim_suffix("]") + ")"
	if target != NodePath():
		hint_str += " on " + str(target)
	return hint_str


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/function.svg")
