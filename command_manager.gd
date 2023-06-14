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

const _GoToCommand = preload("res://addons/blockflow/commands/command_goto.gd")
const _ReturnCommand = preload("res://addons/blockflow/commands/command_return.gd")
const _ConditionCommand = preload("res://addons/blockflow/commands/command_condition.gd")

## Current timeline.
@export var current_timeline:Timeline = null

## This is the node were commands will be applied to.
## This node is used if the command doesn't define an [member Command.target]
## and is relative to the current scene node owner.
@export_node_path var command_node_fallback_path:NodePath = ^"."
## If is [code]true[/code], the node will call [method start_timeline] when owner is ready.
@export var start_on_ready:bool = false


## Current executed command.
var current_command:Command = null
## The current command index relative to [member timeline] resource.
var current_command_idx:int = -1

# [ [<Timeline>, <index>], ... ]
# [           0            , ... ]
var _history:Array = []

# [ 
#   [ history_index, 
#     {from: <Timeline>, idx: <index>}, 
#     {to: <Timeline>, idx: <index>} 
#   ] 
# ]
var _jump_history:Array = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if start_on_ready:
		call_deferred("start_timeline")

## Starts timeline. This method must be called to start CommandManager process.
## CommandManager will use [member]current_timeline[/member] if no 
## [code]timeline[/code] was passed.
## You can optionally pass [code]from_command_index[/code] to define from
## where the timeline should start.
func start_timeline(timeline:Timeline = null, from_command_index:int = 0) -> void:
	current_command = null
	current_command_idx = from_command_index
	if timeline:
		current_timeline = timeline
	_notify_timeline_start()
	go_to_next_command()

## Advances to a specific command in the [member]current_timeline[/member].
## If [code]timeline[/code] is a valid timeline, replaces the current timeline.
func go_to_command(command_idx:int, timeline:Timeline=null) -> void:
	# Check if there's a new timeline
	if not(timeline == null or timeline == current_timeline):
		current_timeline = timeline
		# and if so, notify that it started
		_notify_timeline_start()
	
	if not current_timeline:
		# For some reason, there's no defined timeline.
		assert(false, str(self)+"::go_to_command: Trying to use an unexisting timeline!")
		return
	
	current_command = current_timeline.get_command(command_idx)
	current_command_idx = command_idx
	
	if current_command == null:
		_notify_timeline_end()
		return
	
	_execute_command(current_command)
	# Add to history
	# TODO: Consider moving to its own function.
	_history.append([current_timeline, current_command_idx])
	# Add to jump history
	# TODO: Consider moving to its own function.
	if (current_command as _GoToCommand) != null: 
		_jump_history.append(
			[
				_history.size()-1,
				{"from":current_timeline, "index":current_command_idx},
				{
					"to":current_command.get_target_timeline(),
					"index":current_command.get_target_command_index()
				}
			])

## Advances to the next command in the current timeline.
func go_to_next_command() -> void:
	current_command_idx = max(0, current_command_idx)
	if current_command:
		current_command_idx += 1
	go_to_command(current_command_idx)

func go_to_previous_command() -> void:
	assert(false)
	pass


func _execute_command(command:Command) -> void:
	if command == null:
		assert(false)
		return
	
	var node:Node = get_node(command_node_fallback_path)
	
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
	
	command.execution_steps.call()


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
