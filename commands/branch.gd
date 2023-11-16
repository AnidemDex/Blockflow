@tool
extends "res://addons/blockflow/commands/command.gd"

var branch_name:StringName

@export var condition:String = "true":
	set(value):
		condition = value
		emit_changed()
	get:
		return condition
@export var evaluate_next_branch:bool = true

func _execution_steps() -> void: go_to_next_command()

func _condition_is_true() -> bool:
	# Local variables. These can be added as context for condition evaluation.
	var variables:Dictionary = {}
	# must be a bool, but Utils.evaluate can return Variant according its input.
	# TODO: Make sure that condition is a boolean operation
	var evaluated_condition = Blockflow.Utils.evaluate(condition, target_node, variables)
	if (typeof(evaluated_condition) == TYPE_STRING) and (str(evaluated_condition) == condition):
		# For some reason, your condition cannot be evaluated.
		# Here's a few reasons:
		# 1. Your target_node may not have that property you specified.
		# 2. You wrote wrong the property.
		# 3. You wrote wrong the function name.
		push_warning("%s failed. The condition will be evaluated as false." % [self])
		return false
	
	return bool(evaluated_condition)

func get_next_command_position() -> int:
	if _condition_is_true():
		return position + 1
	
	var owner := get_command_owner()
	if not owner:
		# There's no command owner defined?
		return -1
	
	var sibling_command := get_next_available_command()
	# Only works for consecutive branches.
	if evaluate_next_branch:
		if sibling_command:
			return sibling_command.position
	
	if sibling_command and not is_instance_of(sibling_command, Branch):
		return sibling_command.position
	
	# No more commands?
	if owner is Blockflow.CommandCollectionClass:
		return -1
	
	var owner_sibling = owner.get_next_available_command()
	
#	while owner.get_next_available_command() == null:
	while owner_sibling == null:
		owner = owner.get_command_owner()
		if owner == null or owner is Blockflow.CommandCollectionClass:
			return -1
		owner_sibling = owner.get_next_available_command()
	
	return owner_sibling.position

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/sub-branch.svg")

func _get_name() -> StringName:
	var name := branch_name
	if name.is_empty():
		name = &"Branch"
	return name

func _get_hint() -> String:
	var hint_str = "if " + condition
	if target != NodePath():
		hint_str += " on " + str(target)
	return hint_str

func _can_hold_commands() -> bool: return true
