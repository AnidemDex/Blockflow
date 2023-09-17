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
@export var bookmark:StringName = "":
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

## The command name. Use [method _get_name] to define the name. [br]
## Command name is used by editor, it'll displayed in item the first column
## next to command icon.
## The command name is also used when editor is creating command buttons in
## editor.
## [codeblock]
## func _get_name() -> StringName:
##     return &"Example Command"
## [/codeblock]
var command_name:StringName :
	set(value): return
	get: return _get_name()

## Comand icon displayed in editor. 
## [br]
## Use [method _get_icon] to define the icon. It'll be displayed in item first column.
## [codeblock]
## func _get_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
var command_icon:Texture :
	set(value): return
	get: return _get_icon()

## Command hint. Use [method _get_hint] to define the command hint. [br]
## It will be displayed on command item middle column, 
## useful to preview values previously set in inspector.
## [codeblock]
## func _get_hint() -> String:
##     return "Hi, I'm command %s" % command_name
## [/codeblock]
var command_hint:String :
	set(value): return
	get: return _get_hint()

## Command hint icon. Use [method _get_hint_icon] to define the texture. [br]
## This texture will be displayed before [command_hint].
## [codeblock]
## func _get_hint_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
var command_hint_icon:Texture :
	set(value): return
	get: return _get_hint_icon()

## Command description is used by editor and will be show as tooltip hint. [br]
## Use [method _get_description] to define the description.
## [codeblock]
## func _get_description() -> String:
##     return "This is an example command"
## [/codeblock]
var command_description:String :
	set(value): return
	get: return _get_description()


## Target node that [member target] points to. This value is assigned by
## [member command_manager] before command execution if [member target] is a
## valid path, else node assigned in
## [member command_manager.command_node_fallback_path] is used instead.
var target_node:Node

## Current command position in the timeline.
## Index is determined by timeline and should not be set during runtime.
var index:int

## A [WeakRef] that points to the timeline that holds this command.
var weak_timeline:WeakRef

var editor_block:TreeItem

var branch_names:PackedStringArray:
	set(value): return
	get: return _get_branch_names()

# A [WeakRef] that points to the command owner of this command
var group_owner:WeakRef

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


func _get_name() -> StringName:
	assert(!resource_name.is_empty(), "_get_name()")
	return "UNKNOW_COMMAND" if resource_name.is_empty() else resource_name

func _get_icon() -> Texture:
	return null

func _get_hint() -> String:
	return ""

func _get_hint_icon() -> Texture:
	return null

func _get_description() -> String:
	return ""

func _get_branch_names() -> PackedStringArray:
	return []

func _to_string() -> String:
	return "<Command [%s:%s] #%s>" % [command_name,index,get_instance_id()]

func _init() -> void:
	resource_local_to_scene = true
