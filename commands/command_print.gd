@tool
extends "res://addons/blockflow/commands/command_comment.gd"

func _execution_steps() -> void:
	print(comment)
	super()

func _get_name() -> StringName: return &"Print"
