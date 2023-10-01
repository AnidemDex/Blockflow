@tool
extends Command

@export var branch_name:StringName

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _get_name() -> StringName: return branch_name

func _can_hold_commands() -> bool: return true
func _can_be_selected() -> bool: return false
func _can_be_moved() -> bool: return false
