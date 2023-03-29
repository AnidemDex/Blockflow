extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Return"


func _get_command_desc() -> String:
	return ""


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")

