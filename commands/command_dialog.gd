@tool
extends Command

@export var showname:String = "":
	set(value):
		showname = value
		emit_changed()
	get:
		return showname
@export_multiline var dialog:String:
	set(value):
		dialog = value
		emit_changed()
	get:
		return dialog
@export var additive:bool = false:
	set(value):
		additive = value
		emit_changed()
	get:
		return additive
@export_range(0, 10.0) var letter_delay:float = 0.02:
	set(value):
		letter_delay = value
		emit_changed()
	get:
		return letter_delay
@export var wait_until_finished:bool = true:
	set(value):
		wait_until_finished = value
		emit_changed()
	get:
		return wait_until_finished

func _execution_steps() -> void:
	command_started.emit()
	
	target_node.dialog(showname, dialog, additive, letter_delay)
	if wait_until_finished:
		target_node.dialog_finished.connect(
			dialog_finished,
			CONNECT_ONE_SHOT
			)
	else:
		command_finished.emit()

func dialog_finished():
	command_finished.emit()

func _get_name() -> String:
	return "Dialog"


func _get_hint() -> String:
	return showname + ": " + dialog


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/speech.svg")

