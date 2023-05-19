@tool
extends Resource
class_name Command

## Base class for all commands.
##
## Every command relies on this class. 
## If you want to do your own command, you should [code]extend[/code] from this class.
##

## Emmited when the event starts its execution.
signal command_started
## Emmited when the command finishes its execution.
signal command_finished

## Marks this command with a [code]bookmark[/code]. This bookmark will be registered in
## the timeline when the timeline is loaded, and will be used when other
## command refers to that specific bookmark.
## Bookmarks should be unique.
@export var bookmark:String = "":
	set(value):
		bookmark = value
		emit_changed()
	get: return bookmark

## Determines if the command will go to next event inmediatly or not. 
## If value is true, the next event will be executed when command ends.
@export var continue_at_end:bool = true:
	set(value):
		continue_at_end = value
		emit_changed()
	get: return continue_at_end

## Target [NodePath] this command points to.
## This value is used in runtime by its command manager to determine
## the [member target_node] and is always relative to current scene
## [member Node.owner]
@export var target:NodePath = NodePath():
	set(value):
		target = value
		emit_changed()
		notify_property_list_changed()
	get: return target

## Execution steps that will be called to execute the command behaviour.
var execution_steps:Callable = _execution_steps

## [class CommandManager] node that is executing this node.
## This value is assigned by its current command manager and
## should not be assigned manually.
var command_manager:Node

## Target node that [member target] points to. This value is assigned by
## [member command_manager] before command execution if [member target] is a
## valid path, else node assigned in
## [member command_manager.command_node_fallback_path] is used instead.
var target_node:Node

## Current command position in the timeline.
## Index is determined by timeline and should not be set during runtime.
var index:int

## Returns this command name.
func get_command_name() -> String:
	return _get_name()

## Returns this comand icon.
func get_icon() -> Texture:
	return _get_icon()

## Returns this command hint.
func get_hint() -> String:
	return _get_hint()

## Returns this command hint icon.
func get_hint_icon() -> Texture:
	return _get_hint_icon()

## Returns this command description.
func get_description() -> String:
	return _get_description()


## Defines the execution behaviour of this command.
## This function is the default value of [member execution_steps]
## and you should override it if you are defining the command in a
## script.[br][br]
## [color=yellow]Warning:[/color] always emit [signal command_started]
## when you start your command behaviour and emit [signal command_finished]
## when the command is over.[br][br]
## A common implementation follows:
## [codeblock]
## func _execution_steps() -> void:
##     command_started.emit()
##
##     print("Hello world")
##
##     command_finished.emit()
##
## [/codeblock]
func _execution_steps() -> void:
	assert(false, "_execution_steps")


## Returns this comman name.
## Command name is used by editor, it'll displayed in item the first column
## next to command icon.
## The command name is also used when editor is creating command buttons in
## editor.
func _get_name() -> String:
	assert(false, "_get_name()")
	return "UNKNOW_COMMAND"


## Returns this command icon.
## Command icon is used by editor. It'll be displayed in item first column.
func _get_icon() -> Texture:
	return null


## Returns this command hint. 
## The returned string will be displayed
## on command item middle column, useful to preview values previously set
## in inspector.
func _get_hint() -> String:
	return ""


## Returns this command hint icon.
## The returned texture will be displayed before command hint.
func _get_hint_icon() -> Texture:
	return null

## Returns this command description.
## Command description is used by editor and will be show as tooltip hint.
func _get_description() -> String:
	return ""


func _to_string() -> String:
	return "<Command[%s]#%s>" % [get_command_name(),get_instance_id()]

func _init() -> void:
	resource_local_to_scene = true
