@tool
extends "res://addons/blockflow/commands/command.gd"
## Jump to a specific index in the command collection

const _Utils = preload("res://addons/blockflow/core/utils.gd")

## Whether to use a bookmark (true) or index (false) as the destination
var use_bookmark:bool:
	set(value):
		use_bookmark = value
		emit_changed()
		notify_property_list_changed()
	get: return use_bookmark

## The command index to use as destination
var command_index:int:
	set(value):
		command_index = value
		emit_changed()
	get: return command_index

## The command bookmark to use as destination
var command_bookmark:String:
	set(value):
		command_bookmark = value
		emit_changed()
	get: return command_bookmark

## If not null, which collection to jump to
var target_collection:Collection:
	set(value):
		target_collection = value
		emit_changed()
	get: return target_collection

## @deprecated
var timeline:
	set(value):
		push_warning("timeline is deprecated and will be removed in future versions")
		timeline = value
		emit_changed()
	get: return timeline

## The condition to evaluate. If false, this command is skipped.
## You can reference variables and even call functions, for example:[br]
## [code]value == true[/code][br]
## [code]not child.visible[/code][br]
## [code]get_index() == 2[/code][br]
## etc.
var condition:String:
	set(value):
		condition = value
		emit_changed()
	get:
		return condition

## Helper function to get the defined [timeline]
func get_target_collection() -> Blockflow.CommandCollectionClass:
	var target_c:Blockflow.CommandCollectionClass = target_collection
	# Workaroung while we try to remove @deprecate d timeline
	if (not target_c) and timeline != null:
		target_c = timeline.get_collection_equivalent()
	
	var current_collection = command_manager.main_collection
	if not target_c:
		target_c = current_collection
	
	return target_c

## Helper function to get the defined command index according to [command_index]
## and [command_bookmark]
func get_target_command_index() -> int:
	if use_bookmark:
		var target_timeline:Blockflow.CommandCollectionClass = get_target_collection()
		var target_command:Blockflow.CommandClass = target_timeline.get_command_by_bookmark(command_bookmark)
		command_index = target_command.position
	return command_index


func _execution_steps() -> void:
	command_started.emit()
	# This is an special command. It doesn't emmits a finished signal
	# since it controls the command manager directly
	
	if _condition_is_true():
		_go_to_defined_command()
		return
	
	# unless it fails and the condition is not true.
	command_finished.emit()


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


func _go_to_defined_command() -> void:
	var _target:Blockflow.CommandCollectionClass = get_target_collection()
	var target_command:int = get_target_command_index()
	
	command_manager.jump_to_command(target_command, _target)


func _get_name() -> StringName:
	return "Go To"


func _get_hint() -> String:
	var hint_str = ""
	if use_bookmark:
		hint_str += "bookmark: " + command_bookmark
	else:
		hint_str += "index: " + str(command_index)
	if target_collection != null:
		hint_str += " on collection "
		if target_collection.resource_name.is_empty():
			hint_str += "'" + target_collection.resource_path + "'"
		else:
			hint_str += "'" + target_collection.resource_name + "'"
	if not condition.is_empty():
		hint_str += " if " + str(condition)
	return hint_str


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/jump.svg")


func _get_property_list():

	var properties = [
		{
			"name": "condition",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
			"hint_string":"true"
		},
		{
			"name": "use_bookmark",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "command_index",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT if not use_bookmark else 0,
		},
		{
			"name": "command_bookmark",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT if use_bookmark else 0,
		},
#		{
#			"name": "timeline", # @deprecated
#			"type": TYPE_OBJECT,
#			"class_name": "Timeline",
#			"usage": PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_READ_ONLY,
#			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "Timeline"
#		},
		{
			"name": "target_collection",
			"type": TYPE_OBJECT,
			"class_name": "CommandCollection",
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "CommandCollection"
		},
	]

	return properties


func _get_category() -> StringName:
	return &"Flow"
