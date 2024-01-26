@tool
extends "res://addons/blockflow/commands/command.gd"

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

## If [code]true[/code], the [param value] will be [b]added[/b] instead of [b]set[/b].[br]
## To [b]subtract[/b], use a negative value like [param value] of -1
var add_value:bool = false:
	set(value):
		add_value = value
		emit_changed()
	get: return add_value

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
## If [param value_type] is in [param PlusOperables], [param add_value] can be used.
var value:
	set(_val):
		value = _val
		emit_changed()

func _execution_steps() -> void:
	command_started.emit()
	
	if add_value:
		var original_value = target_node.get(property)
		var original_type = typeof(original_value)
		if not (original_type in PlusOperables) or value_type != original_type:
			push_error("Can't add a value to a non operable property")
		else:
			var new_value = original_value + value
			target_node.set(property, new_value)
	else:
		target_node.set(property, value)
	
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
	if add_value:
		operator = "+="
	hint += property + " " + operator + " " + str(fake_value)
	return hint

func _get_property_list() -> Array:
	var p := []
	
	p.append({"name":"value", "type":value_type, "usage":PROPERTY_USAGE_DEFAULT})
	
	if value_type in PlusOperables:
		p.append({"name":"add_value", "type":TYPE_BOOL, "usage":PROPERTY_USAGE_DEFAULT})
	
	return p


func _get_category() -> StringName:
	return &"Engine"
