@tool
extends Command

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

func _execution_steps() -> void:
	stop()

func _get_name() -> StringName: return &"End"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/stop.svg")
