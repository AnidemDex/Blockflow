## Util functions

# Based on: https://www.askpython.com/python/built-in-methods/python-eval
## Evaluates a string, excecutes it and returns the result
static func evaluate(input:String, global:Object=null, locals:Dictionary={}, _show_error:bool=true):
	var _evaluated_value = null
	var _expression = Expression.new()
	
	var _err = _expression.parse(input, PackedStringArray(locals.keys()))
	
	if _err != OK:
		push_warning(_expression.get_error_text())
	else:
		_evaluated_value = _expression.execute(locals.values(), global, _show_error)
		
		if _expression.has_execute_failed():
			push_error("Utils::evaluate( %s ) -> Execution failed, returning input." % [input])
			return input
		
	return _evaluated_value

static func get_object_data(object:Object) -> Dictionary:
	const CollectionClass = preload("res://addons/blockflow/collection.gd")
	const ProcessorClass = preload("res://addons/blockflow/command_processor.gd")
	const CommandClass = preload("res://addons/blockflow/commands/command.gd")
	const CCollectionClass = preload("res://addons/blockflow/command_collection.gd")
	
	var data:Dictionary = {}
	if not is_instance_valid(object): return data
	
	data[&"id"] = object.get_instance_id()
	if object is Node:
		data[&"path"] = object.get_path()
		data[&"name"] = object.name
		if is_instance_of(object, ProcessorClass):
			data[&"main_collection"] = get_object_data(object.main_collection)
			data[&"current_collection"] = get_object_data(object.current_collection)
			data[&"current_command"] = get_object_data(object.current_command)
		return data
	
	if is_instance_of(object, CollectionClass):
		data[&"class"] = &"Collection"
		if is_instance_of(object, CommandClass):
			data[&"class"] = &"Command"
			data[&"name"] = object.command_name
			data[&"index"] = object.index
			data[&"position"] = object.position
			if is_instance_valid(object.command_manager):
				data[&"processor"] = object.command_manager.get_instance_id()
		
		if is_instance_of(object, CCollectionClass):
			data[&"class"] = &"CommandCollection"
			data[&"name"] = object.resource_path
			data[&"bookmarks"] = {}
			for bookmark in object._bookmarks.keys():
				var command = object._bookmarks[bookmark]
				data[&"bookmarks"][bookmark].append(command.get_instance_id())
			data[&"command_list"] = []
			for command in object._command_list:
				data[&"command_list"].append(get_object_data(command))
		
		data[&"collection"] = []
		for command in object.collection:
			data[&"collection"].append(get_object_data(command))
		return data
	
	return data

static func obj_to_str(object:Object) -> void:
	push_error("Not implemented")
	return

static func str_to_obj(string:String) -> void:
	push_error("Not implemented")
	return
