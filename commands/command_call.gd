@tool
extends "res://addons/blockflow/commands/command.gd"
## A command to use to call a function on a node with or without arguments.

## The method to call. You can [Select a Method] by picking an existing node,
## or [Edit Method] to set it up manually.
@export var method:String:
	set(value):
		method = value
		emit_changed()
	get:
		return method

## The arguments to pass to the method to call.
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
	var properties = ""
	for arg in args:
		if arg is Resource:
			arg = "<" + arg.resource_path + ">"
		properties += str(arg) + ", "
	var hint_str = method + "(" + properties.trim_suffix(", ") + ")"
	if target != NodePath():
		hint_str += " on " + str(target)
	return hint_str


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/function.svg")


func _get_category() -> StringName:
	return &"Engine"
