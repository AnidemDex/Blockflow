@tool
extends Command

func _execution_steps() -> void:
	pass


func _get_name() -> StringName:
	return "Condition"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _get_default_branch_names() -> PackedStringArray:
	return [&"is True", &"is False"]
