@tool
extends Command

@export var behavior:CommandProcessor.ReturnValue = CommandProcessor.ReturnValue.AFTER

func _execution_steps() -> void:
	command_started.emit()
	command_manager.return_to_previous_jump(behavior)


func _get_name() -> StringName:
	return "Return"

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
