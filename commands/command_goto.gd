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

var verify_condition_once:bool = true

func _execution_steps() -> void:
	command_started.emit()
	# This is an special command. It doesn't emmits a finished signal
	# since it controls the command manager directly
	
	if verify_condition_once and _condition_is_true():
		_go_to_defined_command()
		return
	
	(Engine.get_main_loop() as SceneTree).process_frame.connect(_fake_process, CONNECT_ONE_SHOT)


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
	var target_timeline:Timeline = command_manager.timeline
	
	if timeline:
		target_timeline = timeline
	
	if use_bookmark:
		var target_command = target_timeline.get_command_by_bookmark(command_bookmark)
		command_index = target_timeline.get_command_idx(target_command)
	
	if timeline:
		# Now looking at it, this seems wrong.
		command_manager.timeline = timeline
		command_manager.start_timeline(command_index)
		return
	
	command_manager.go_to_command(command_index)


func _fake_process() -> void:
	if _condition_is_true():
		_go_to_defined_command()
	else:
		(Engine.get_main_loop() as SceneTree).process_frame.connect(_fake_process, CONNECT_ONE_SHOT)


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
