@tool
extends "res://addons/blockflow/commands/command.gd"

## @deprecated
## TYPE_INT,[br]TYPE_FLOAT,[br]TYPE_VECTOR2,[br]TYPE_VECTOR2I,[br]TYPE_VECTOR3,[br]TYPE_VECTOR3I,[br]TYPE_VECTOR4,[br]TYPE_VECTOR4I,[br]TYPE_COLOR,[br]TYPE_STRING,[br]TYPE_STRING_NAME,[br]TYPE_ARRAY,[br]29,[br]30,[br]31,[br]32,[br]33,[br]34,[br]35,[br]36,[br]37
const PlusOperables = [
	TYPE_INT, TYPE_FLOAT,
	TYPE_VECTOR2, TYPE_VECTOR2I,
	TYPE_VECTOR3, TYPE_VECTOR3I,
	TYPE_VECTOR4, TYPE_VECTOR4I,
	TYPE_COLOR,
	TYPE_STRING, TYPE_STRING_NAME,
	TYPE_ARRAY, 29, 30, 31, 32, 33, 34, 35, 36, 37
]

const Operables = [
	TYPE_INT, TYPE_FLOAT,
	TYPE_VECTOR2, TYPE_VECTOR2I,
	TYPE_VECTOR3, TYPE_VECTOR3I,
	TYPE_VECTOR4, TYPE_VECTOR4I,
	TYPE_COLOR,
	TYPE_STRING, TYPE_STRING_NAME,
	TYPE_ARRAY, 29, 30, 31, 32, 33, 34, 35, 36, 37
]

## Will perform the selected operation on the target value.
@export_enum("Set", "Add", "Subtract", "Multiply", "Divide", "Power of", "X root of") var operation: int = 0:
	set(val):
		operation = val
		emit_changed()
	get: return operation
## The path towards the [param property] from [param target] (such as [member name] etc.)
@export var property:String:
	set(value):
		property = value
		emit_changed()
	get: return property

## Sets the type for the [param value] to set the [param property] to.
@export var value_type:Variant.Type = TYPE_NIL:
	set = set_value_type

## What value to set the [param property] to.[br]
var value:
	set(_val):
		value = _val
		emit_changed()

func _execution_steps() -> void:
	command_started.emit()
	if operation == 0:
		_add_variable(property, value_type, value, target_node)
	if operation != 0: 
		var original_value
		if target_node.get(property) != null:
			original_value = target_node.get(property)
		elif target_node.get_meta(property) != null:
			original_value = target_node.get_meta(property)
		else:
			push_error("Cannot operate on a non-defined variable!")
			return
		var original_type = typeof(original_value)
		if not (original_type in Operables) or value_type != original_type:
			push_error("Can't operate a number to a non operable property")
		else:
			var new_value
			match operation:
				1: new_value = original_value + value
				2: new_value = original_value - value
				3: new_value = original_value * value
				4: new_value = original_value / value
				5: new_value = pow(original_value, value)
				6: new_value = pow(original_value, 1/value)
			_add_variable(property, value_type, new_value, target_node)
	go_to_next_command()

func set_value_type(type:Variant.Type) -> void:
	value_type = type
	if type in [TYPE_RID, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_MAX]:
			value_type = TYPE_NIL
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
	if property.is_empty():
		return hint
	
	if not target.is_empty():
		hint += str(target)+"."
	var fake_value := str(value)
	if value is Resource:
		fake_value = "<" + value.resource_path + ">"
	if fake_value.is_empty():
		fake_value = "<Not Defined>"
	var operator = "="
	match operation:
		1: operator = "+="
		2: operator = "-="
		3: operator = "*="
		4: operator = "/="
	if operation != 5 and operation != 6: 
		hint += property + " " + operator + " " + str(fake_value)
	elif operation == 5: 
		hint += property + " = " + property + " to the power of " + str(fake_value)
	elif operation == 6 and value == 1:
		hint += property + " = " + property +  " (The first root of a value is the same as that value)"
	elif operation == 6 and value == 2:
		hint += property + " = " + "square root of " + property
	elif operation == 6 and value == 3:
		hint += property + " = " + "cube root of " + property
	elif operation == 6 and  str(value)[str(value).length() - 2] != "1" and str(value)[str(value).length() - 1] == "2": 
		hint += property + " = " + str(fake_value) + "nd root of " + property
	elif operation == 6 and str(value)[str(value).length() - 2] != "1" and str(value)[str(value).length() - 1] == "3":
		hint += property + " = " + str(fake_value) + "rd root of " + property
	elif operation == 6:
		hint += property + " = " + str(fake_value) + "th root of " + property
	return hint

func _get_property_list() -> Array:
	var p := []
	
	p.append({"name":"value", "type":value_type, "usage":PROPERTY_USAGE_DEFAULT})
	
	return p


func _get_category() -> StringName:
	return &"Engine"
