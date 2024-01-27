@tool
extends "res://addons/blockflow/commands/command.gd"
## Prints can be used to output information to the game's console.

## Text to be output into the console
@export_multiline var comment:String:
	set(value):
		comment = value
		emit_changed()
	get:
		return comment

func _execution_steps() -> void:
	command_started.emit()
	print(comment)
	command_finished.emit()

func _get_name() -> StringName: return &"Print"


func _get_hint() -> String:
	return comment


func _get_color() -> Color:
	return Color(0.6,0.8,0.6,1)


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/console.svg")


func _get_category() -> StringName:
	return &"Debug"
