@tool
extends "res://addons/blockflow/commands/command.gd"
## Simply end command processing here

func _execution_steps() -> void:
	stop()

func _get_name() -> StringName: return &"End"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/stop.svg")


func _get_category() -> StringName:
	return &"Flow"

