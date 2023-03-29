extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Wait"


func _get_command_desc() -> String:
	return "2.45 seconds"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/Timer.svg")

