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
## This is emited if [member current_collection] is different
## from the collection that is about to be used.
##
## [br][Collection] resource is passed in the signal.
signal collection_started(collection)

## Emited when a [Collection] finish. 
## A [Collection] is considered finished when there are no more
## commands to be processed.
##
## [br][Collection] resource is passed in the signal.
signal collection_finished(collection)

enum ReturnValue {
	BEFORE=-1, ## Returns a command behind go_to caller
	AFTER=1, ## Returns a command after go_to caller
	NO_RETURN, ## Ends inmediatly the execution process and end the timeline.
	}

enum _HistoryData {COLLECTION, COMMAND_POSITION}
enum _JumpHistoryData {HISTORY_INDEX, FROM, TO}

@export var initial_collection:CommandCollection
## Node were commands will be applied to.
##
## [br]This node is used if the command doesn't 
## define a [member Command.target]
## and is relative to the current scene node [member Node.owner].
@export_node_path var command_node_fallback_path:NodePath = ^"."

## If [code]true[/code], the node will call [method start_timeline]
## when owner is ready automatically.
@export var start_on_ready:bool = false

var current_collection:Collection

## Current executed command.
var current_command:Command = null

## The current command index relative to [member timeline] resource.
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
## CommandManager will use [member]current_timeline[/member] if no 
## [code]timeline[/code] was passed.
## You can optionally pass [code]from_command_index[/code] to define from
## where the timeline should start.
func start(collection:CommandCollection = null, from_command_index:int = 0) -> void:
	current_command = null
	current_command_position = from_command_index
	if collection:
		current_collection = collection
	_notify_process_started()
	go_to_command(current_command_position)

## Advances to a specific command in the [member current_timeline]
## according [param command_position].
## If [param in_collection] is valid, replaces [member current_timeline]
## and go to the command in [param command_position].
func go_to_command(command_position:int, in_collection:Collection=null) -> void:
	# Check if there's a new timeline
	if in_collection != null or in_collection != current_collection:
		current_collection = in_collection
		# and if so, notify that it started
		_notify_process_started()
	
	if not current_collection:
		# For some reason, there's no defined timeline.
		assert(false, str(self)+"::go_to_command: Trying to use an unexisting Collection!")
		return
	
	# Prevents an error and ends the timeline if there are no more commands
	if command_position >= current_collection.get_command_count():
		_notify_process_finished()
		return
	
	current_command = current_collection.get_command(command_position)
	current_command_position = command_position
	
	if current_command == null:
		_notify_process_finished()
		return
	
	_prepare_command(current_command)
	_add_to_history()
	
	_execute_command(current_command)

## Advances to the next available command.
func go_to_next_command() -> void:
	current_command_position = get_next_command_position()
	if current_command_position >= current_collection.get_command_count():
		push_warning("current_command_position > current_collection.get_command_count()")
	go_to_command(current_command_position)

## Return to the previous comman in history
func go_to_previous_command() -> void:
	assert(!_history.is_empty())
	var history_data:Array = _history.pop_back()
	var previous_collection:Collection = history_data[_HistoryData.COLLECTION]
	var previous_position:int = history_data[_HistoryData.COMMAND_POSITION]
	go_to_command(previous_position, previous_collection)


func jump_to_command(command_position:int, on_collection:Collection) -> void:
	if not on_collection:
		on_collection = current_collection
	_add_to_jump_history(command_position, on_collection)
	go_to_command(command_position, on_collection)


func return_to_previous_jump(return_value:ReturnValue):
	assert(!_jump_history.is_empty())
	if return_value == ReturnValue.NO_RETURN:
		_notify_process_finished()
		_disconnect_command_signals(current_command)
		return
	
	var jump_data:Array = _jump_history.pop_back()
	var history_from:Array = jump_data[ _JumpHistoryData.FROM ]
	
	var next_command_position:int = history_from\
	[ _HistoryData.COMMAND_POSITION ] + return_value
	
	var next_collection:Collection =  history_from[ _HistoryData.COLLECTION ]
	
	go_to_command(next_command_position, next_collection)


func get_next_command_position() -> int:
	if not current_collection:
		return -1
	
	if current_command_position < 0:
		return 0
	
	var next_position:int = current_command_position + 1
	if current_command and current_command.can_hold_commads:
		if current_command.commands.size() > 0:
			next_position = current_command.commands.get_command(0).index
	
	return next_position


func _prepare_command(command:Command) -> void:
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
		target_node = self
	command.target_node = target_node


func _execute_command(command:Command) -> void:
	if command == null:
		assert(false)
		return
	
	command.execution_steps.call()


func _add_to_history() -> void:
	assert(bool(current_collection != null))
	var history_value = []
	history_value.resize(_HistoryData.size())
	history_value[_HistoryData.COLLECTION] = current_collection
	history_value[_HistoryData.COMMAND_POSITION] = current_command_position
	_history.append(history_value)


# Adds a history value to [_jump_history].
# This function should NEVER be called manually.
# Called by [go_to_command] if the current command is GoTo command.
func _add_to_jump_history(target_position:int, target_collection:Collection) -> void:
	assert(bool(current_collection != null))
	var jump_data := []
	var history_from := []
	var history_to := []
	jump_data.resize(_JumpHistoryData.size())
	history_from.resize(_HistoryData.size())
	history_to.resize(_HistoryData.size())
	
	history_from[_HistoryData.COLLECTION] = current_collection
	history_from[_HistoryData.COMMAND_POSITION] = current_command_position
	jump_data[_JumpHistoryData.FROM] = history_from
	
	history_to[_HistoryData.COLLECTION] = target_collection
	history_to[_HistoryData.COMMAND_POSITION] = target_position
	jump_data[_JumpHistoryData.TO] = history_to
	
	jump_data[_JumpHistoryData.HISTORY_INDEX] = _history.size()-1
	jump_data[_JumpHistoryData.FROM] = history_from
	jump_data[_JumpHistoryData.TO] = history_to
	_jump_history.append(jump_data)

func _connect_command_signals(command:Command) -> void:
	if not command.is_connected("command_started", _on_command_started):
		command.command_started.connect(_on_command_started.bind(command), CONNECT_ONE_SHOT)
	if not command.is_connected("command_finished", _on_command_finished):
		command.command_finished.connect(_on_command_finished.bind(command), CONNECT_ONE_SHOT)


func _disconnect_command_signals(command:Command) -> void:
	if command.is_connected("command_started", _on_command_started):
		command.command_started.disconnect(_on_command_started)
	if command.is_connected("command_finished", _on_command_finished):
		command.command_finished.disconnect(_on_command_finished)

func _notify_process_started() -> void:
	return

func _notify_process_finished() -> void:
	return

func _on_command_started(command:Command) -> void:
	command_started.emit(command)

func _on_command_finished(command:Command) -> void:
	command_finished.emit(command)
	if command.continue_at_end:
		go_to_next_command()

func _hide_script_from_inspector():
	return true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if Engine.is_editor_hint(): return
			
			if start_on_ready:
				if get_parent().is_node_ready():
					start()
				else:
					get_parent().ready.connect(start.bind(initial_collection), CONNECT_ONE_SHOT)
			return
