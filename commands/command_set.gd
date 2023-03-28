extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Set Variable"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/sliders.svg")

