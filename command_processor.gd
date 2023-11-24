extends Node
class_name CommandProcessor

##
## Process the execution of commands in a collection.
##
## [CommandProcessor] executes the command behaviour, 
## according a given [Collection],
## process the command order execution, their conditions,
## branching and history.
## 

## Emited when a [Command] requires to emit an arbitrary signal with
## custom data
signal custom_signal(data)

## Emmited when [CommandProcessor] is about to call 
## [member Command.execution_steps].
##
## [br][Command] resource is passed in the signal [param command]
signal command_started(command)

## Emited when a previously executed command
## emits [signal Command.command_finished].
## Not all commands emits this signal when they finish their
## [member Command.execution_steps] behavior.
##
## [br][Command] resource is passed in the signal.
signal command_finished(command)

## Emited when a [Collection] starts.
## This is emited if [member current_collection] or
## [member main_collection] is different
## from the collection that were being used.
##
## [br][Collection] resource is passed in the signal.
signal collection_started(collection)

## Emited when a [Collection] finish. 
## A [Collection] is considered finished when there are no more
## commands to be processed or [member current_collection] or
## [member main_collection] changes.
##
## [br][Collection] resource is passed in the signal.
signal collection_finished(collection)

enum ReturnValue {
	BEFORE=-1, ## Returns a command behind jump_to caller
	REPEAT, ## Returns to last jump_to caller
	AFTER=1, ## Returns a command after jump_to caller
	NO_RETURN, ## Ends inmediatly the execution process and end the timeline.
	}

enum _HistoryData {COLLECTION, COMMAND_POSITION}
enum _JumpHistoryData {HISTORY_INDEX, FROM, TO}

const Blockflow = preload("res://addons/blockflow/blockflow.gd")

## Initial collection that will be used if [method start] is called without arguments.
@export var initial_collection:Blockflow.CommandCollectionClass

## Node were commands will be applied to.
##
## [br]This node is used if the command doesn't 
## define a [member Command.target]
## and is relative to the current scene node [member Node.owner].
@export_node_path var command_node_fallback_path:NodePath = ^"."

## If [code]true[/code], the node will call [method start_timeline]
## when owner is ready automatically.
@export var start_on_ready:bool = false

## Main [CommandCollection] used.
var main_collection:Blockflow.CommandCollectionClass

## Current [Collection] used.
var current_collection:Blockflow.CollectionClass

## Current executed [Command].
var current_command:Blockflow.CommandClass

## The [member current_command] position according to [member main_collection].
var current_command_position:int = -1

# [ [<Timeline>, <index>], ... ]
# [           0            , ... ]
var _history:Array = []

# [ 
#   [ history_index,  <- Points to _history
#     [<Timeline>, <index>] <- from, 
#     [<Timeline>, <index>] <- to
#   ] 
# ]
var _jump_history:Array = []

## Starts the command behavior. This method must be called to start CommandManager process.
## CommandManager will use [member initial_collection] if no 
## [param collection] is passed.
## You can optionally pass [param from_command_index] to define the initial
## position that will be used.
func start(collection:Blockflow.CommandCollectionClass = null, from_command_index:int = 0) -> void:
	current_command = null
	current_command_position = from_command_index
	main_collection = initial_collection
	current_collection = initial_collection
	if collection:
		main_collection = collection
		current_collection = collection
	collection_started.emit(current_collection)
	go_to_command(current_command_position)

## Advances to a specific command in the [member main_collection].
func go_to_command(command_position:int) -> void:
	if not main_collection:
		# For some reason, there's no defined main collection.
		assert(false, str(self)+"::go_to_command: Trying to use an unexisting Collection!")
		return
	
	# Prevents an error and ends the processing if there are no more commands
	if command_position >= main_collection.get_command_count():
		assert( false, str(self)+"::go_to_command: Can't advance to command in position %s"%command_position )
		return
	
	var command:Blockflow.CommandClass = main_collection.get_command(command_position)
	
	if command == null:
		assert( false, str(self)+"::go_to_command: current_command == null")
		return
	
	current_command = command
	current_command_position = current_command.position
	current_collection = current_command.weak_owner.get_ref()
	
	_prepare_command(current_command)
	_add_to_history()
	
	_execute_command(current_command)

## Advances to certain command in [param collection] at given [param command_position]
func go_to_command_in_collection(command_position:int, collection:Blockflow.CollectionClass) -> void:
	if not collection:
		assert(false)
		return
	
	var command:Blockflow.CommandClass = collection.get_command(command_position)
	if not command:
		assert(false)
		return
	
	var main_collection_changed:bool
	var current_collection_changed:bool
	# Seems like we're in a different collection
	if command.weak_collection.get_ref() != main_collection:
		collection_finished.emit(main_collection)
		main_collection = command.weak_collection.get_ref()
		main_collection_changed = true
	
	if command.weak_owner.get_ref() != current_collection:
		collection_finished.emit(current_collection)
		current_collection = command.weak_owner.get_ref()
		current_collection_changed = true
	
	if current_collection != collection:
		push_warning("current_collection != collection")
	
	if not main_collection:
		assert(false)
		return
	
	if main_collection_changed:
		collection_started.emit(main_collection)
	
	if current_collection_changed:
		collection_started.emit(current_collection)
	
	current_command = command
	current_command_position = current_command.index
	
	_prepare_command(current_command)
	_add_to_history()
	
	_execute_command(current_command)

## Advances to the next available command.
func go_to_next_command() -> void:
	var next_command_position = get_next_command_position()
	# Seems like there are no more available commands?
	if next_command_position < 0 or next_command_position >= main_collection.get_command_count():
		collection_finished.emit(main_collection)
		return
	current_command_position = next_command_position
	
	go_to_command(current_command_position)

## Return to the previous comman in history
func go_to_previous_command() -> void:
	assert(!_history.is_empty())
	var history_data:Array = _history.pop_back()
	var previous_collection:Blockflow.CollectionClass = history_data[_HistoryData.COLLECTION]
	var previous_position:int = history_data[_HistoryData.COMMAND_POSITION]
	go_to_command_in_collection(previous_position, previous_collection)

## Jumps to a command, appending the call to jump history.
func jump_to_command(command_position:int, on_collection:Blockflow.CollectionClass) -> void:
	if not on_collection:
		on_collection = current_collection
	_add_to_jump_history(command_position, on_collection)
	go_to_command_in_collection(command_position, on_collection)

## Returns to last [method jump_to_command] call according to [param return_value].
##[br]See [enum ReturnValue] for possible values.
func return_to_previous_jump(return_value:ReturnValue):
	assert(!_jump_history.is_empty())
	if return_value == ReturnValue.NO_RETURN:
		stop()
		return
	
	var jump_data:Array = _jump_history.pop_back()
	var history_from:Array = jump_data[ _JumpHistoryData.FROM ]
	
	var next_command_position:int = history_from\
	[ _HistoryData.COMMAND_POSITION ] + return_value
	
	var next_collection:Blockflow.CollectionClass =  history_from[ _HistoryData.COLLECTION ]
	
	go_to_command_in_collection(next_command_position, next_collection)

## Stops behavior. Current command finished status will be ignored and current 
## collection will be threated as finished.
func stop() -> void:
	collection_finished.emit(current_collection)
	_disconnect_command_signals(current_command)

## Get the next available command position or -1 if there is none.
func get_next_command_position() -> int:
	if not current_collection:
		return -1
	
	if not current_command:
		return 0
	
	if current_command_position < 0:
		return 0
	
	var next_position:int = current_command.get_next_command_position()
	
	return next_position


func _prepare_command(command:Blockflow.CommandClass) -> void:
	if command == null:
		assert(false)
		return
	
	_connect_command_signals(command)
	
	command.command_manager = self
	var ref_node:Node = owner
	if not is_instance_valid(ref_node):
		ref_node = get_tree().current_scene
	
	var target_node:Node = ref_node.get_node_or_null(command.target)
	if not is_instance_valid(target_node):
		target_node = get_node_or_null(command_node_fallback_path)
	if not is_instance_valid(target_node):
		push_warning("Can't define Command.target_node")
	command.target_node = target_node


func _execute_command(command:Blockflow.CommandClass) -> void:
	if command == null:
		assert(false)
		return
	
	var main_collection_data := Blockflow.Utils.get_object_data(main_collection)
	var curr_collection_data := Blockflow.Utils.get_object_data(current_collection)
	
	Blockflow.Debugger.processing_collection(get_instance_id(), main_collection_data)
	Blockflow.Debugger.processing_collection(get_instance_id(), curr_collection_data)
	Blockflow.Debugger.processing_command(get_instance_id(), Blockflow.Utils.get_object_data(command))
	
	command.execution_steps.call()


func _add_to_history() -> void:
	assert(bool(main_collection != null))
	var history_value = []
	history_value.resize(_HistoryData.size())
	history_value[_HistoryData.COLLECTION] = main_collection
	history_value[_HistoryData.COMMAND_POSITION] = current_command_position
	_history.append(history_value)


# Adds a history value to [_jump_history].
# This function should NEVER be called manually.
func _add_to_jump_history(target_position:int, target_collection:Blockflow.CollectionClass) -> void:
	assert(bool(main_collection != null))
	var jump_data := []
	var history_from := []
	var history_to := []
	jump_data.resize(_JumpHistoryData.size())
	history_from.resize(_HistoryData.size())
	history_to.resize(_HistoryData.size())
	
	history_from[_HistoryData.COLLECTION] = main_collection
	history_from[_HistoryData.COMMAND_POSITION] = current_command_position
	jump_data[_JumpHistoryData.FROM] = history_from
	
	history_to[_HistoryData.COLLECTION] = target_collection
	history_to[_HistoryData.COMMAND_POSITION] = target_position
	jump_data[_JumpHistoryData.TO] = history_to
	
	jump_data[_JumpHistoryData.HISTORY_INDEX] = _history.size()-1
	jump_data[_JumpHistoryData.FROM] = history_from
	jump_data[_JumpHistoryData.TO] = history_to
	_jump_history.append(jump_data)

func _connect_command_signals(command:Blockflow.CommandClass) -> void:
	if not command.command_started.is_connected(_on_command_started):
		command.command_started.connect(_on_command_started.bind(command), CONNECT_ONE_SHOT)
	if not command.command_finished.is_connected(_on_command_finished):
		command.command_finished.connect(_on_command_finished.bind(command), CONNECT_ONE_SHOT)


func _disconnect_command_signals(command:Blockflow.CommandClass) -> void:
	if command.command_started.is_connected(_on_command_started):
		command.command_started.disconnect(_on_command_started)
	if command.command_finished.is_connected(_on_command_finished):
		command.command_finished.disconnect(_on_command_finished)

func _on_command_started(command:Blockflow.CommandClass) -> void:
	command_started.emit(command)

func _on_command_finished(command:Blockflow.CommandClass) -> void:
	command_finished.emit(command)
	if command.continue_at_end:
		go_to_next_command()

func _hide_script_from_inspector():
	return true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if Engine.is_editor_hint(): return
			
			Blockflow.Debugger.register_processor(Blockflow.Utils.get_object_data(self))
			
			if start_on_ready:
				if get_parent().is_node_ready():
					start()
				else:
					get_parent().ready.connect(start.bind(initial_collection), CONNECT_ONE_SHOT)
			return
		
		NOTIFICATION_PREDELETE:
			Blockflow.Debugger.unregister_processor(get_instance_id())
