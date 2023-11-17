@tool
extends "res://addons/blockflow/commands/command.gd"

@export_multiline var comment:String:
	set(value):
		comment = value
		emit_changed()
	get:
		return comment

func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()

func _get_name() -> StringName:
	return "Comment"


func _get_hint() -> String:
	return "# " + comment


func _get_color() -> Color:
	return Color(0.8,0.8,1,0.5)


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/comment.svg")
