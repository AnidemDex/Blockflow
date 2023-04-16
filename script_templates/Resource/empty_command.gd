# meta-name: Command
# meta-description: Empty command template
# meta-default: true
extends Command

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "CUSTOM_COMMAND"


func _get_icon() -> Texture:
	return load("res://icon.svg")
