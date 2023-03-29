extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Call"


func _get_command_desc() -> String:
	return "set_color(25, 25, 255) on Player/Sprite"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/function.svg")


func _get_command_desc_icon() -> Texture:
	return load("res://addons/blockflow/icons/bookmark.svg")
