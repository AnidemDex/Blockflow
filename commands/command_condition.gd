@tool
extends "res://addons/blockflow/commands/command.gd"

const _Utils = preload("res://addons/blockflow/core/utils.gd")
const TrueBranchClass = preload("res://addons/blockflow/commands/branch_true.gd")
const FalseBranchClass = preload("res://addons/blockflow/commands/branch_false.gd")

@export var condition:String
@export var generate_default_branches:bool = true

func _execution_steps() -> void:
	command_started.emit()
	if condition.is_empty():
		push_error("condition.is_empty() == true. Your condition will not be evaluated.")
		return
	
	if _condition_is_true():
		go_to_branch(0)
	else:
		go_to_branch(1)


func _condition_is_true() -> bool:
	if condition.is_empty():
		return true
	
	# Local variables. These can be added as context for condition evaluation.
	var variables:Dictionary = {}
	# must be a bool, but Utils.evaluate can return Variant according its input.
	# TODO: Make sure that condition is a boolean operation
	var evaluated_condition = _Utils.evaluate(condition, target_node, variables)
	if (typeof(evaluated_condition) == TYPE_STRING) and (str(evaluated_condition) == condition):
		# For some reason, your condition cannot be evaluated.
		# Here's a few reasons:
		# 1. Your target_node may not have that property you specified.
		# 2. You wrote wrong the property.
		# 3. You wrote wrong the function name.
		push_warning("%s failed. The condition will be evaluated as false." % [self])
		return false
	
	return bool(evaluated_condition)


func _get_name() -> StringName: return "Condition"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _get_default_branch_for(branch_name:StringName) -> Branch:
	if branch_name == &"is True":
		var b := TrueBranchClass.new()
		b.branch_name = branch_name
		return b
		
	if branch_name == &"is False":
		var b := FalseBranchClass.new()
		b.branch_name = branch_name
		return b
	
	return super(branch_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		if generate_default_branches:
			var branches = [TrueBranchClass, FalseBranchClass]
			for command in collection:
				if command.get_script() in branches:
					branches.erase(command.get_script())
			for branch in branches:
				add(branch.new())
			
			generate_default_branches = false
