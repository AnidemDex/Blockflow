@tool
extends "res://addons/blockflow/commands/branch.gd"

func _condition_is_true() -> bool: return not super()

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/false.svg")

func _init() -> void:
	branch_name = "is False"
