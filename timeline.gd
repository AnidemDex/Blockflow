@tool
extends Collection
class_name Timeline
##
## Base class for all Timelines
##
## Deprecated. Legacy class.
##

var commands:Array[Command]:
	set(value):
		commands = value
		_notify_changed()
	get:
		return commands

func get_collection_equivalent() -> CommandCollection:
	var collection := CommandCollection.new()
	collection.collection = commands.duplicate()
	return collection

func _init() -> void:
	push_warning(
"""[%s]Timeline: This class is deprecated and will be removed in
future versions.
Consider using CommandCollection class."""%resource_path
	)


func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"commands", "type":TYPE_ARRAY, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE})
	return p
