@tool
extends "res://addons/blockflow/commands/command.gd"

@export var branch_name:StringName

var condition:String
var evaluate_next_branch:bool = true

func _execution_steps() -> void: go_to_next_command()

func _condition_is_true() -> bool:
	return true

func get_next_command_position() -> int:
	if _condition_is_true():
		return position + 1
	
	var owner := get_command_owner()
	if not owner:
		# There's no command owner defined?
		return -1
	
	# Only works for consecutive branches.
	if evaluate_next_branch:
		if get_next_available_command():
			return get_next_available_command().position
	
	if not is_instance_of(get_next_available_command(), Branch):
		return get_next_available_command().position
	
	while owner.get_next_available_command() == null:
		owner = owner.get_command_owner()
		if owner == null:
			return -1
	
	return owner.get_next_available_command().position

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _get_name() -> StringName: return branch_name

func _can_hold_commands() -> bool: return true
