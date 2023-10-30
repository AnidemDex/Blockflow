@tool
extends Command


func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()
	command_manager._notify_timeline_end()
	command_manager._disconnect_command_signals(command_manager.current_command)


func _get_name() -> String:
	return "End Timeline"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/stop.svg")

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
