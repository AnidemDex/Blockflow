@tool
extends Command

func _execution_steps() -> void:
	pass


func _get_name() -> String:
	return "Animate"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/animation.svg")
