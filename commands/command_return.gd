@tool
extends Command

@export_enum("Repeat:0", "Next:1") var behavior: int = 1:
	set(value):
		behavior = value
		emit_changed()
	get:
		return behavior


@export var to_last_timeline:bool = false:
	set(value):
		to_last_timeline = value
		emit_changed()
	get:
		return to_last_timeline


func _execution_steps() -> void:
	command_started.emit()
	command_manager.return_command(behavior, to_last_timeline)


func _get_name() -> String:
	return "Return"


func _get_hint() -> String:
	return ("to last timeline" if to_last_timeline else "to last jump") +\
		(" (repeat)" if behavior == 0 else "")


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/return.svg")

# stop at end by default
func _property_can_revert(property: StringName) -> bool:
	if property == "continue_at_end":
		return true
	return false

func _property_get_revert(property: StringName):
	if property == "continue_at_end":
		return false
	return null

func _init() -> void:
	super()
	continue_at_end = false
