extends Node

@export var timeline:Timeline

func play():
	pass

##
## Base class for all command manager nodes.
##
## commandManager executes the command behaviour, and manages the command order execution.
## 

signal custom_signal(data)

## Emmited when an command is executed. command resource is passed in the signal
signal command_started(command)
## Emmited when an command finished. command resource is passed in the signal.
signal command_finished(command)

## Emmited when a timeline starts. Timeline resource is passed in the signal
signal timeline_started(timeline_resource)
## Emmited when a timeline finish. Timeline resource is passed in the signal
signal timeline_finished(timeline_resource)

## This is the node were commands will be applied to.
## This node is used if the command doesn't define an [member command.command_node_path]
## and is relative to the current scene node owner.
@export_node_path var command_node_fallback_path:NodePath = ^"."
## If is [code]true[/code], the node will call [method start_timeline] when owner is ready.
@export var start_on_ready:bool = false


## Current executed command.
var current_command:Command
## The current command index relative to [member timeline] resource.
var current_command_idx:int = -1

var _commands:Array[Command]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if start_on_ready:
		call_deferred("start_timeline")

## Starts timeline. This method must be called to start CommandManager process.
## You can optionally pass [code]from_command_index[/code] to define from
## where the timeline should start.
func start_timeline(from_command_index:int=0) -> void:
	_commands = timeline.commands
	current_command = null
	current_command_idx = from_command_index
	_notify_timeline_start()
	go_to_next_command()

## Advances to a specific command in the current timeline.
func go_to_command(command_idx:int) -> void:
	if not timeline:
		# For some reason, the timeline doesn't exist
		assert(false)
		return
	
	current_command = timeline.get_command(command_idx)
	current_command_idx = command_idx
	
	if current_command == null:
		_notify_timeline_end()
		return
	
	_execute_command(current_command)

## Advances to the next command in the current timeline.
func go_to_next_command() -> void:
	current_command_idx = max(0, current_command_idx)
	if current_command:
		current_command_idx += 1
	go_to_command(current_command_idx)


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
	timeline_started.emit()


func _notify_timeline_end() -> void:
	timeline_finished.emit()


func _hide_script_from_inspector():
	return true
