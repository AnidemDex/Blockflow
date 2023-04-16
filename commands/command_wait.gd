@tool
extends Command

@export var wait_time:float

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "Wait"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/Timer.svg")


func _get_hint_icon() -> Texture:
	return load("res://addons/blockflow/icons/bookmark.svg")
