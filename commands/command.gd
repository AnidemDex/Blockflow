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

const Group = preload("res://addons/blockflow/commands/group.gd")
const Branch = preload("res://addons/blockflow/commands/branch.gd")

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
## By default, it uses [method _execution_steps], you can override
## that method to define your own steps.
var execution_steps:Callable = _execution_steps

## [CommandManager] node that is executing this command.
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
##
## [br]Use [method _get_icon] to define the icon. It'll be displayed in item first column.
## [codeblock]
## func _get_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
var command_icon:Texture :
	set(value): return
	get: return _get_icon()

## Command hint. Use [method _get_hint] to define the command hint.
## [br]It will be displayed on command item middle column, 
## useful to preview values previously set in inspector.
## [codeblock]
## func _get_hint() -> String:
##     return "Hi, I'm command %s" % command_name
## [/codeblock]
var command_hint:String :
	set(value): return
	get: return _get_hint()

## Command hint icon. Use [method _get_hint_icon] to define the texture.
## [br]This texture will be displayed before [command_hint].
## [codeblock]
## func _get_hint_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
var command_hint_icon:Texture :
	set(value): return
	get: return _get_hint_icon()

## Command description is used by editor and will be show as tooltip hint.
## [br]Use [method _get_description] to define the description.
## [codeblock]
## func _get_description() -> String:
##     return "This is an example command"
## [/codeblock]
var command_description:String :
	set(value): return
	get: return _get_description()

## [CommandBlock] item assigned by editor.
## [br]This reference is assigned by timeline displayer editor.
var editor_block:TreeItem

## Target node that [member target] points to. This value is assigned by
## [member command_manager] before command execution if [member target] is a
## valid path, else node assigned in
## [member command_manager.command_node_fallback_path] is used instead.
var target_node:Node

## Current command position in the timeline.
## Index is determined by timeline and should not be set during runtime.
var index:int

## A [WeakRef] that points to the timeline that holds this command.
var weak_collection:WeakRef

## Branches of this command using a [Collection].
##
## [br]A [code]branch[/code] is a subcommand of this command 
## that can hold other commands. Each branch defined as command in
## the [Collection] must be [constant Branch] type.
##
## [br]Any command can hold many branches, and  can request their usage
## through [method go_to_brach].
##
## [br]Branches and its contained commands
## are ignored if you use [method go_to_next_command].
var branches:Collection:
	set(value):
		if branches == value: return
		if branches: branches.weak_owner = null
		
		branches = value
		if branches: branches.weak_owner = weakref(self)
		emit_changed()

## A [WeakRef] that points to the owner of this command.
## [br]The return value of [method weak_owner.get_ref] is
## [Collection] or null.
##[br]If value is null it means that owner failed to set
## its own reference.
var weak_owner:WeakRef

## Subcommands of this command using [Collection].
##[br]If [member can_hold_commands] is [code]true[/code]
## a [Collection] object will be set on creation.
var commands:Collection:
	set(value):
		if commands == value: return
		if commands: commands.weak_owner = null
		
		commands = value
		if commands: commands.weak_owner = weakref(self)
		emit_changed()

## If [code]true[/code] enables
## the option to drop commands on this command
## to handle them as subcommands.
var can_hold_commads:bool :
	set(value): return
	get: return _can_hold_commands()

var can_be_moved:bool :
	set(value): return
	get: return _can_be_moved()

var can_be_selected:bool :
	set(value): return
	get: return _can_be_selected()

var _branches:Dictionary

func add_branch(branch_name:StringName) -> void:
	if branch_name in _branches:
		return
	
	if not branches:
		push_error("!branches")
		return
	
	for branch in branches:
		if branch.command_name == branch_name:
			return
	
	var branch := Branch.new()
	branch.branch_name = branch_name
	_branches[branch_name] = branch
	branches.add(branch)
	emit_changed()
	

func remove_branch(branch_name:StringName) -> void:
	_branches.erase(branch_name)
	for branch in branches:
		if branch.command_name == branch_name:
			branches.erase(branch)
	emit_changed()

func get_branch(branch) -> Command:
	match typeof(branch):
		TYPE_INT:
			return branches.get_command(branch)
		TYPE_STRING:
			return _branches.get(branch, null)
		_:
			push_error("typeof(branch) != TYPE_INT | TYPE_STRING")
	return null

## Request [member command_manager] go to the next available command.
## [br][member command_manager] will go to the next subcommand if there's any.
## It will not use a branch as the next command. Use
## [method go_to_branch] instead.
func go_to_next_command() -> void:
	command_finished.emit()

## Request [member command_manager] to go to a specific
## command in the timeline with [param command_index].
## [br][Command], [member commands] and [member branches] are taken 
## in consideration for this index.
## [br][br]Note: Calling this method will not trigger 
## [signal command_finished] and will go to the requested
## [param command_index] inmediatly.
func go_to_command(command_index:int) -> void:
	command_manager.jump_to_command(command_index, null)

## Request [member command_manager] to go to a specific branch defined in
## [member branches].
## [param branch] can be:
## [br]  - [String] value, it'll match any branch with that name,
## branch names must be unique or it'll use last match
## [br]  - [int] value, it'll use the branch according 
## [member branches.get_command]
func go_to_branch(branch) -> void:
	match typeof(branch):
		TYPE_INT:
			if branch < branches.size():
				command_manager.go_to_command(index + branch)
				return
		TYPE_STRING:
			var _branches:Dictionary
			for _branch in branches:
				_branches[_branch.command_name] = _branch
			if branch in _branches:
				command_manager.go_to_command(_branches[branch].index)
				return
			# untested stuff, hope it works
		_:
			push_error("typeof(branch) != TYPE_INT | TYPE_STRING")
	push_error("!branch")
	command_finished.emit()


## Defines the execution behaviour of this command.
## This function is the default value of [member execution_steps]
## and you should override it if you are defining the command in a
## script.[br]
##
## [br]A common implementation follows:
## [codeblock]
## func _execution_steps() -> void:
##     print("Hello world")
##
##     go_to_next_command()
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

func _can_be_moved() -> bool:
	return true

func _can_be_selected() -> bool:
	return true

func _get_description() -> String:
	return ""

func _can_hold_commands() -> bool:
	return false

func _get_default_branch_names() -> PackedStringArray:
	return []

func _to_string() -> String:
	return "<Command [%s:%s] #>" % [command_name,index]

func _set(property: StringName, value) -> bool:
	if property.begins_with("default_branch"):
		var name:String = property.split("/")[1]
		if name in _get_default_branch_names():
			add_branch(name)
			return true
	return false

func _get(property: StringName):
	if property.begins_with("default_branch"):
		var name:String = property.split("/")[1]
		return get_branch(name)

func _init() -> void:
	resource_local_to_scene = true
	if not _get_default_branch_names().is_empty():
		branches = Collection.new()
	
	for branch_name in _get_default_branch_names():
		add_branch(branch_name)
	
	if can_hold_commads:
		commands = Collection.new()

func _get_property_list() -> Array:
	var p:Array = []
	p.append({"name":"commands", "type":TYPE_OBJECT, "usage":PROPERTY_USAGE_NO_EDITOR})
	p.append({"name":"branches", "type":TYPE_OBJECT, "usage":PROPERTY_USAGE_NO_EDITOR})
	for branch_name in _get_default_branch_names():
		p.append({"name":"default_branch/"+branch_name, "type":TYPE_OBJECT})
	return p
