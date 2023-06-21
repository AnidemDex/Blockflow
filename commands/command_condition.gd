@tool
extends Command

const _Utils = preload("res://addons/blockflow/core/utils.gd")

var condition:String = "true"
var add_else:bool = false

var _true_commands_quantity:int = 1
var _false_commands_quantity:int = 1

var _true_commands:PackedInt32Array = []
var _false_commands:PackedInt32Array = []

func _execution_steps() -> void:
	var curr_timeline:Timeline = command_manager.current_timeline
	var curr_pos:int = command_manager.current_command_idx
	
	if _true_commands_quantity <= 0:
		push_warning("""Command doesn't have any commands to execute if the condition is true. 
		Execution will be skipped and CommandManager process will continue normally""")
		command_finished.emit()
		return
	
	for i in _true_commands_quantity:
		var command_idx = curr_pos+1+i
		_true_commands.append(command_idx)

	for i in _false_commands_quantity:
		var command_idx = curr_pos+1+_true_commands_quantity+i
		_false_commands.append(command_idx)
	
	
	command_started.emit()
#	prints(_true_commands, "[", _true_commands_quantity, "]", "<- True commands")
#	prints(_false_commands, "[", _false_commands_quantity, "]", "<- False commands")
	if _condition_is_true():
#		print("Condition is true, go_to_command->",_true_commands[0])
		command_manager.command_finished.connect(_command_manager_command_finished)
		command_manager.go_to_command(_true_commands[0])
	else:
#		print("Condition is false, go_to_command->",_false_commands[0])
		command_manager.go_to_command(_false_commands[0])


func _command_manager_command_finished(command) -> void:
	var next_command = command_manager.current_command_idx+1
#	prints("next command:", next_command)
	if next_command in _false_commands:
#		print("--Condition was true and next command is part of false commands, skipping--")
		command_manager.current_command_idx += _false_commands_quantity
		command_manager.command_finished.disconnect(_command_manager_command_finished)
#		prints("next command:", command_manager.current_command_idx+1)


func _condition_is_true() -> bool:
	if condition.is_empty():
		return false
	
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
		push_warning("%s condition check failed. The condition will be evaluated as false." % [self])
		return false
	
	return bool(evaluated_condition)


func _get_name() -> String:
	return "Condition"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/branch.svg")

func _uses_subcommands() -> bool:
	return true

func _uses_custom_subcommands() -> PackedStringArray:
	return ["Condition is true", "Condition is false"]

func _edit_custom_subcommands() -> Dictionary:
	return {}
