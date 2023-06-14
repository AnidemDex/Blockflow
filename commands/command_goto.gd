@tool
extends Command

const _Utils = preload("res://addons/blockflow/core/utils.gd")

var use_bookmark:bool:
	set(value):
		use_bookmark = value
		emit_changed()
		notify_property_list_changed()
	get: return use_bookmark

var command_index:int:
	set(value):
		command_index = value
		emit_changed()
	get: return command_index

var command_bookmark:String:
	set(value):
		command_bookmark = value
		emit_changed()
	get: return command_bookmark

var timeline:Timeline:
	set(value):
		timeline = value
		emit_changed()
	get: return timeline

var condition:String:
	set(value):
		condition = value
		emit_changed()
	get:
		return condition

## Helper function to get the defined [timeline]
func get_target_timeline() -> Timeline:
	var target_timeline:Timeline = timeline
	var current_timeline:Timeline = command_manager.current_timeline
	if not target_timeline:
		target_timeline = current_timeline
	
	return target_timeline

## Helper function to get the defined command index according to [command_index]
## and [command_bookmark]
func get_target_command_index() -> int:
	var target_timeline = get_target_timeline()
	var target_command = command_index
	if use_bookmark:
		target_command = target_timeline.get_command_by_bookmark(command_bookmark)
		command_index = target_timeline.get_command_idx(target_command)
	return target_command


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
	var target_timeline:Timeline = get_target_timeline()
	var target_command:int = get_target_command_index()
	
	command_manager.go_to_command(target_command, target_timeline)


func _get_name() -> String:
	return "Go To"


func _get_hint() -> String:
	var hint_str = ""
	if use_bookmark:
		hint_str += "bookmark: " + command_bookmark
	else:
		hint_str += "index: " + str(command_index)
	if timeline:
		hint_str += " on timeline "
		if timeline.resource_name.is_empty():
			hint_str += "'" + timeline.resource_path + "'"
		else:
			hint_str += "'" + timeline.resource_name + "'"
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
			"hint":PROPERTY_HINT_EXPRESSION
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
		{
			"name": "timeline",
			"type": TYPE_OBJECT,
			"class_name": "Timeline",
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Timeline"
		},
	]

	return properties
