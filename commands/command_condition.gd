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
		stop()
		return
	for command in collection:
		if typeof(command.get("condition")) == TYPE_STRING:
			command.set("condition", condition + command.get("condition"))
			command.set("target", target)
	go_to_next_command()

func _get_name() -> StringName: return "Condition"

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _can_hold_commands() -> bool: return true

func can_hold(command) -> bool:
	return command.is_branch()

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		if generate_default_branches:
			var branches = [TrueBranchClass, FalseBranchClass]
			for command in collection:
				if command.get_script() in branches:
					branches.erase(command.get_script())
			for branch in branches:
				collection.append(branch.new())
			
			generate_default_branches = false
