@tool
extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Condition"


func _get_command_desc() -> String:
	return "if x is true, then"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")


func _get_command_desc_icon() -> Texture:
	return load("res://addons/blockflow/icons/bookmark.svg")
