@tool
extends "res://addons/blockflow/commands/command.gd"

const PlusOperables = [
	TYPE_INT, TYPE_FLOAT,
	TYPE_VECTOR2, TYPE_VECTOR2I,
	TYPE_VECTOR3, TYPE_VECTOR3I,
	TYPE_VECTOR4, TYPE_VECTOR4I,
	TYPE_COLOR,
	TYPE_STRING, TYPE_STRING_NAME,
	TYPE_ARRAY, 29, 30, 31, 32, 33, 34, 35, 36, 37
]

var add_value:bool = false

@export var property_path:String

@export var property_type:Variant.Type = TYPE_NIL:
	set = set_property_type

var value:
	set(_val):
		value = _val
		emit_changed()

func _execution_steps() -> void:
	command_started.emit()
	
	if add_value:
		var original_value = target_node.get(property_path)
		var original_type = typeof(original_value)
		if not (original_type in PlusOperables) or property_type != original_type:
			push_error("Can't add a value to a non operable property")
		else:
			var new_value = original_value + value
			target_node.set(property_path, new_value)
	else:
		target_node.set(property_path, value)
	
	go_to_next_command()

func set_property_type(type:Variant.Type) -> void:
	property_type = type
	if type in [TYPE_RID, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_MAX]:
			property_type = TYPE_NIL
			push_error("Trying to assign a non serializable type")
			value = null
	else:
		value = Blockflow.Utils.get_default_value_for_type(type)
	
	notify_property_list_changed()
	emit_changed()

func _get_name() -> StringName:
	return "Set Variable"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/sliders.svg")

func _get_hint() -> String:
	var hint:String = ""
	if property_path.is_empty():
		return hint
	
	if not target.is_empty():
		hint += str(target)+"."
	
	var fake_value := str(value)
	if fake_value.is_empty():
		fake_value = "<Not Defined>"
	
	hint += property_path + " = " + str(fake_value)
	return hint

func _get_property_list() -> Array:
	var p := []
	
	p.append({"name":"value", "type":property_type, "usage":PROPERTY_USAGE_DEFAULT})
	
	if property_type in PlusOperables:
		p.append({"name":"add_value", "type":TYPE_BOOL, "usage":PROPERTY_USAGE_DEFAULT})
	
	return p
