extends Node
class_name CommandManager
##
## Manages the execution of timelines.
##
## [CommandManager] executes the command behaviour, and manages the command order execution.
## 

signal custom_signal(data)

## Emmited when an command is executed. [Command] resource is passed in the signal
signal command_started(command)
## Emmited when an command finished. [Command] resource is passed in the signal.
signal command_finished(command)

## Emmited when a timeline starts. [Timeline] resource is passed in the signal
signal timeline_started(timeline_resource)
## Emmited when a timeline finish. [Timeline] resource is passed in the signal
signal timeline_finished(timeline_resource)

## Return values used in [return_command]
enum ReturnValue {
	BEFORE=-1, ## Returns a command behind go_to caller
	AFTER=1, ## Returns a command after go_to caller
	NO_RETURN, ## Ends inmediatly the execution process and end the timeline.
	}

const _GoToCommand = preload("res://addons/blockflow/commands/command_goto.gd")
const _ReturnCommand = preload("res://addons/blockflow/commands/command_return.gd")
const _ConditionCommand = preload("res://addons/blockflow/commands/command_condition.gd")

enum _HistoryData {TIMELINE, COMMAND_INDEX}
enum _JumpHistoryData {HISTORY_INDEX, FROM, TO}

## Current timeline.
@export var current_timeline:Timeline = null

## Node were commands will be applied to.
## [br]This node is used if the command doesn't 
## define a [member Command.target]
## and is relative to the current scene node [member Node.owner].
@export_node_path var command_node_fallback_path:NodePath = ^"."
## If [code]true[/code], the node will call [method start_timeline]
## when owner is ready automatically.
@export var start_on_ready:bool = false


## Current executed command.
var current_command:Command = null
## The current command index relative to [member timeline] resource.
var current_command_position:int = -1

# [ [<Timeline>, <index>], ... ]
# [           0            , ... ]
var _history:Array = []

# [ 
#   [ history_index, 
#     [<Timeline>, <index>] <- from, 
#     [<Timeline>, <index>] <- to
#   ] 
# ]
var _jump_history:Array = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if start_on_ready:
		if get_parent().is_node_ready():
			start_timeline()
		else:
			get_parent().ready.connect(start_timeline, CONNECT_ONE_SHOT)

## Starts timeline. This method must be called to start CommandManager process.
## CommandManager will use [member]current_timeline[/member] if no 
## [code]timeline[/code] was passed.
## You can optionally pass [code]from_command_index[/code] to define from
## where the timeline should start.
func start_timeline(timeline:Timeline = null, from_command_index:int = 0) -> void:
	current_command = null
	current_command_position = from_command_index
	if timeline:
		current_timeline = timeline
	_notify_timeline_start()
	go_to_command(current_command_position)

## Advances to a specific command in the [member current_timeline].
## If [code]timeline[/code] is a valid timeline, replaces the current timeline.
func go_to_command(command_position:int, timeline:Timeline=null) -> void:
	# Check if there's a new timeline
	if not(timeline == null or timeline == current_timeline):
		current_timeline = timeline
		# and if so, notify that it started
		_notify_timeline_start()
	
	if not current_timeline:
		# For some reason, there's no defined timeline.
		assert(false, str(self)+"::go_to_command: Trying to use an unexisting timeline!")
		return
	
	# Prevents an error and ends the timeline if there are no more commands
	if command_position >= current_timeline.get_command_count() :
		_notify_timeline_end()
		return
	
	current_command = current_timeline.get_command(command_position)
	current_command_position = command_position
	
	if current_command == null:
		_notify_timeline_end()
		return
	
	_prepare_command(current_command)
	_add_to_history()
	
	_execute_command(current_command)
	

## Advances to the next command in the current timeline.
func go_to_next_command() -> void:
	current_command_position = get_next_command_index()
	print(">>",current_command_position, " ", current_timeline.get_command_count())
	if current_command_position >= current_timeline.get_command_count():
		push_warning("current_command_position > current_timeline.get_command_count()")
	go_to_command(current_command_position)

func go_to_previous_command() -> void:
	assert(!_history.is_empty())
	var history_data:Array = _history.pop_back()
	var previous_timeline:Timeline = history_data[_HistoryData.TIMELINE]
	var previous_position:int = history_data[_HistoryData.COMMAND_INDEX]
	go_to_command(previous_position, previous_timeline)
	pass

func jump_to_command(command_position:int, on_timeline:Timeline) -> void:
	if not on_timeline:
		on_timeline = current_timeline
	_add_to_jump_history(command_position, on_timeline)
	go_to_command(command_position, on_timeline)

## Returns to a previous [code]go_to[/code] command call.
## See [enum ReturnValue] to know possible values for [code]return_value[/code]
## argument.
func return_command(return_value:ReturnValue):
	assert(!_jump_history.is_empty())
	if return_value == ReturnValue.NO_RETURN:
		_notify_timeline_end()
		_disconnect_command_signals(current_command)
		return
	
	var jump_data:Array = _jump_history.pop_back()
	var history_from:Array = jump_data[ _JumpHistoryData.FROM ]
	
	var next_command_idx:int = history_from\
	[ _HistoryData.COMMAND_INDEX ] + return_value
	
	var next_timeline:Timeline =  history_from[ _HistoryData.TIMELINE ]
	
	go_to_command(next_command_idx, next_timeline)

func get_next_command_index() -> int:
	if not current_timeline:
		return -1
	
	if current_command_position < 0:
		return 0
	
	var next_position:int = current_command_position + 1
	if current_command:
		if current_command.commands.size() > 0:
			next_position = current_command.commands.get_command(0).index
	
	return next_position

func get_previous_command_index() -> int:
	if not current_timeline:
		return -1
	
	var position:int = max(current_command_position - 1, -1)
	if not _history.is_empty():
		position = _history[-1][_HistoryData.COMMAND_INDEX]
	return position

# Set required data for a command. Used before _execute_command
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

# Adds a history value to [_history].
# This function should NEVER be called manually.
# Called by [method go_to_command]
func _add_to_history() -> void:
	assert(bool(current_timeline != null))
	var history_value = []
	history_value.resize(_HistoryData.size())
	history_value[_HistoryData.TIMELINE] = current_timeline
	history_value[_HistoryData.COMMAND_INDEX] = current_command_position
	_history.append(history_value)

# Adds a history value to [_jump_history].
# This function should NEVER be called manually.
# Called by [go_to_command] if the current command is GoTo command.
func _add_to_jump_history(target_position:int, target_timeline:Timeline) -> void:
	assert(bool(current_timeline != null))
	var jump_data := []
	var history_from := []
	var history_to := []
	jump_data.resize(_JumpHistoryData.size())
	history_from.resize(_HistoryData.size())
	history_to.resize(_HistoryData.size())
	
	history_from[_HistoryData.TIMELINE] = current_timeline
	history_from[_HistoryData.COMMAND_INDEX] = current_command_position
	jump_data[_JumpHistoryData.FROM] = history_from
	
	history_to[_HistoryData.TIMELINE] = target_timeline
	history_to[_HistoryData.COMMAND_INDEX] = target_position
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


func _on_command_started(command:Command) -> void:
	command_started.emit(command)


func _on_command_finished(command:Command) -> void:
	command_finished.emit(command)
	if command.continue_at_end:
		go_to_next_command()


func _notify_timeline_start() -> void:
	timeline_started.emit(current_timeline)


func _notify_timeline_end() -> void:
	timeline_finished.emit()


func _hide_script_from_inspector():
	return true
