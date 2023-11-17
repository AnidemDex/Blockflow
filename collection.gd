@tool
extends Resource
class_name Collection

## Collection of commands.
##
## Collection acts as an array with extra functions
## to interact with the array easily.

enum {
	NOTIFICATION_UPDATE_STRUCTURE = 1<<2 ## Notify that internal structure must be updated.
	}

## Blockflow constant
const Blockflow = preload("res://addons/blockflow/blockflow.gd")

## Emmited when internal [member collection] is modified.
signal collection_changed

## [WeakRef] owner of this collection.
## [br][method weak_owner.get_ref] value can be:
## [br]  - A [CommandCollection]
## [br]  - A [Command], meaning this command is a subcommand of that command.
## [br]  - A [code]null[/code] value, meaning it doesn't has an owner or the
## owner failed setting its own reference.
var weak_owner:WeakRef

## [WeakRef] [CommandCollection] owner of this collection.
## [br][method weak_collection.get_ref] value can be:
## [br]  - A [CommandCollection]
## [br]  - A [code]null[/code] value, meaning it's the "main" [CommandCollection]
var weak_collection:WeakRef

## Array of [Command]
var collection:Array = []:
	set = _set_collection

var is_updating_data:bool

## Adds a [Command] to [member collection]
func add(command) -> void:
	if has(command):
		push_error("Trying to add an command to the collection, but the command is already added")
		return
	collection.append(command)
	command.weak_owner = weakref(self)
	_notify_changed()

## Insert [Command] [param command] at [param position] in [member collection]
func insert(command, at_position:int) -> void:
	if has(command):
		push_error("Trying to add an command to the collection, but the command already exist")
		return
	
	var idx = at_position if at_position > -1 else collection.size()
	collection.insert(idx, command)
	command.weak_owner = weakref(self)
	_notify_changed()

# can't use duplicate lmao
## Copy a [Command] in position [param to_position] of [member collection]
func copy(command, to_position:int) -> void:
	var duplicated = command.get_duplicated()
	var idx = to_position if to_position > -1 else collection.size()
	
	collection.insert(idx, duplicated)
	command.weak_owner = weakref(self)
	_notify_changed()


## Moves a [Command] from its current [Command.index] to [param to_position]
func move(command, to_position:int) -> void:
	if !has(command):
		push_error("Trying to move an command in the collection, but the command is not added.")
		return
	
	var old_position:int = get_command_position(command)
	if old_position < 0:
		return
	
	to_position = to_position if to_position > -1 else collection.size()
	if to_position == old_position:
		return
	
	collection.remove_at(old_position)
	
	if to_position < 0 or to_position >= collection.size():
		collection.append(command)
	else:
		collection.insert(to_position, command)
	
	command.weak_owner = weakref(self)
	_notify_changed()

## Erases a [Command] from [member collection]
func erase(command:Blockflow.CommandClass) -> void:
	collection.erase(command)
	_notify_changed()

## Removes a command from [member collection] at [param position]
func remove(position:int) -> void:
	collection.remove_at(position)
	_notify_changed()

## Clear [member collection]
func clear() -> void:
	collection.clear()
	_notify_changed()

## Get the command at [param position]. 
## [br]You can also use [method get] instead.
func get_command(position:int):
	if position < collection.size():
		return collection[position]
	
	push_error("get_command: Tried to get an command on a non-existing position: ", position)
	return null

## Get the last command in [member collection] or null if collection is empty.
func get_last_command():
	if not collection.is_empty():
		return collection[collection.size()-1]
	return null
	

## Get [Command.index] of [param command] or -1 if the command is not in collection.
func get_command_position(command) -> int:
	return collection.find(command)

func get_duplicated():
	var _duplicate = duplicate(true)
	var new_collection = []
	for command in collection:
		new_collection.append(command.get_duplicated())
	_duplicate.collection = new_collection
	return _duplicate

## Returns true if collection has [param value]
func has(value) -> bool:
	return collection.has(value)

## Searches in [member collection] for a [param command] and returns its index or -1 if not found.
func find(command) -> int:
	return collection.find(command)

## Returns the number of commands that collection contains.
func size() -> int:
	return collection.size()

## Returns true if collection is empty.
func is_empty() -> bool:
	return collection.is_empty()

func _notify_changed() -> void: 
	notification(NOTIFICATION_UPDATE_STRUCTURE)
	Blockflow.generate_tree(self)
	collection_changed.emit()
	emit_changed()

func _set_collection(value:Array) -> void:
	for command in collection:
		command.weak_owner = null
	
	collection = value
	
	_notify_changed()

func _get(property: StringName):
	if property.is_valid_int():
		return get_command(int(property))

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		for command_index in collection.size():
			var command:Command = collection[command_index]
			command.weak_owner = weakref(self)
			command.index = command_index
			command.weak_collection = weak_collection


func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"collection", "type":TYPE_ARRAY, "usage":PROPERTY_USAGE_NO_EDITOR|PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_ALWAYS_DUPLICATE})
	return p

func _to_string() -> String:
	return "<Collection:%d>" % get_instance_id()

func _init() -> void:
	notification(NOTIFICATION_UPDATE_STRUCTURE)

# ITERATOR
var __itr_cnt:int
func _should_continue() -> bool: return __itr_cnt < _get_iterator_ref().size()

func _get_iterator_ref() -> Array: return collection

func _iter_init(_d) -> bool:
	__itr_cnt = 0
	return _should_continue()

func _iter_next(_d) -> bool:
	__itr_cnt += 1
	return _should_continue()
	
func _iter_get(_d):
	return _get_iterator_ref()[__itr_cnt]
