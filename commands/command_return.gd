@tool
extends Command

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "Return"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")
