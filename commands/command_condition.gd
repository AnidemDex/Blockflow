@tool
extends Command

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "Condition"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")
