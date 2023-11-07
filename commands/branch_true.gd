@tool
extends "res://addons/blockflow/commands/branch.gd"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/true.svg")

func _init() -> void:
	branch_name = "is True"
