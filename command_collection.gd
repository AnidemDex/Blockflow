@tool
extends Resource
class_name CommandCollection

## Collection of commands.
##
## CommandCollection acts as an array with extra functions
## to interact with the array easily.

## [WeakRef] owner of this collection.
var weak_owner:WeakRef

var collection:Array[Command] = []:
	set(value):
		collection = value
		for c in value:
			_update_command_owner(c)
		emit_changed()
	get:
		return collection

func add(command:Command) -> void:
	if has(command):
		push_error("Trying to add an command to the collection, but the command is already added")
		return
	collection.append(command)
	_update_command_owner(command)
	emit_changed()

func insert(command:Command, at_position:int) -> void:
	if has(command):
		push_error("Trying to add an command to the collection, but the command already exist")
		return
	
	var idx = at_position if at_position > -1 else collection.size()
	collection.insert(idx, command)
	_update_command_owner(command)
	emit_changed()

# can't use duplicate lmao
func copy(command:Command, to_position:int) -> void:
	var duplicated = command.duplicate()
	var idx = to_position if to_position > -1 else collection.size()
	collection.insert(idx, duplicated)
	_update_command_owner(command)
	emit_changed()

func move(command:Command, to_position:int) -> void:
	if !has(command):
		push_error("Trying to move an command in the collection, but the command is not added.")
		return
	
	var old_position:int = get_command_position(command)
	if old_position < 0:
		return
	
	to_position = to_position if to_position > -1 else collection.size()
	if to_position == old_position:
		emit_changed()
		return
	
	collection.remove_at(old_position)
	
	if to_position < 0 or to_position > collection.size():
		to_position = collection.size()
	
	collection.insert(to_position, command)
	_update_command_owner(command)
	emit_changed()

func erase(command) -> void:
	collection.erase(command)
	emit_changed()

func remove(position:int) -> void:
	collection.remove_at(position)
	emit_changed()

func clear() -> void:
	collection.clear()
	emit_changed()

## Get the command at [param position]. 
## [br]You can also use [method get] instead.
func get_command(position:int) -> Resource:
	if position < collection.size():
		return collection[position]
	
	push_error("get_command: Tried to get an command on a non-existing position: ", position)
	return null

func get_command_position(command) -> int:
	return collection.find(command)

func has(value:Command) -> bool:
	return collection.has(value)

func find(command) -> int:
	return collection.find(command)

func size() -> int:
	return collection.size()

func is_empty() -> bool:
	return collection.is_empty()

func _update_command_owner(command:Command, remove:bool=false) -> void:
	if not weak_owner: return
	if typeof(weak_owner.get_ref()) != TYPE_OBJECT: return
	command.weak_owner = weakref(self)

func _get(property: StringName):
	if property.is_valid_int():
		return get_command(int(property))

func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"collection", "type":TYPE_ARRAY, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE})
	return p

# ITERATOR
var __itr_cnt:int
func _should_continue() -> bool: return __itr_cnt < collection.size()

func _iter_init(_d) -> bool:
	__itr_cnt = 0
	return _should_continue()

func _iter_next(_d) -> bool:
	__itr_cnt += 1
	return _should_continue()
	
func _iter_get(_d):
	return collection[__itr_cnt]
