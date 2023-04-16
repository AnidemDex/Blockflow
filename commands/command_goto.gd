@tool
extends Command

@export var timeline:Timeline
@export var command_label:String

func _execution_steps(manager) -> void:
	pass


func _get_name() -> String:
	return "Go To"


func _get_hint() -> String:
	return "go to #-1"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/jump.svg")


func _get_hint_icon() -> Texture:
	return load("res://addons/blockflow/icons/bookmark.svg")
