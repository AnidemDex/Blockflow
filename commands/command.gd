@tool
extends "res://addons/blockflow/collection.gd"
class_name Command

## Base class for all commands.
##
## Every command relies on this class. 
## If you want to make your own command, you should [code]extend[/code] from this class.
##

## Emmited when the command starts its execution.
signal command_started
## Emmited when the command finishes its execution.
signal command_finished

## @deprecated
const Group = preload("res://addons/blockflow/commands/group.gd")
const Branch = preload("res://addons/blockflow/commands/branch.gd")

## Marks this command with a [code]bookmark[/code]. This bookmark will be registered in
## the [member weak_collection] when the collection is loaded, and will be used when other
## command refers to that specific bookmark.
##
##[br][br]Bookmarks should be unique. If a subsequent command uses the same bookmark
##that command will be used instead.
@export var bookmark:StringName = "":
	set(value):
		bookmark = value
		emit_changed()
	get: return bookmark

## Determines if the command will go to next command inmediatly or not. 
## If value is true, the next command will be executed when command ends.
@export var continue_at_end:bool = true:
	set(value):
		continue_at_end = value
		emit_changed()
	get: return continue_at_end

## Target [NodePath] this command points to.
## This value is used in runtime by its [member command_manager] 
##  to determine the [member target_node] and is always 
## relative to current scene [member Node.owner]
@export var target:NodePath = NodePath():
	set(value):
		target = value
		emit_changed()
		notify_property_list_changed()
	get: return target

#region COMMAND DATA
@export_group("Command Data")
## The command name. Use [method _get_name] to define the name.
##[br]Command name is used by editor, it'll displayed in item the first column
## next to command icon.
## The command name is also used when editor is creating command buttons in
## editor.
## [codeblock]
## func _get_name() -> StringName:
##     return &"Example Command"
## [/codeblock]
@export var command_name:StringName :
	set(value): return
	get: return _get_name()

## Comand icon displayed in editor. 
##
## [br]Use [method _get_icon] to define the icon. It'll be displayed in item first column.
## [codeblock]
## func _get_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
@export var command_icon:Texture :
	set(value): return
	get: return _get_icon()

## Command description is used by editor and will be show as tooltip hint.
## [br]Use [method _get_description] to define the description.
## [codeblock]
## func _get_description() -> String:
##     return "This is an example command"
## [/codeblock]
@export_multiline var command_description:String :
	set(value): return
	get: return _get_description()

## Command hint. Use [method _get_hint] to define the command hint.
## [br]It will be displayed on command item middle column, 
## useful to preview values previously set in inspector.
## [codeblock]
## func _get_hint() -> String:
##     return "Hi, I'm command %s" % command_name
## [/codeblock]
@export_multiline var command_hint:String :
	set(value): return
	get: return _get_hint()

## Command color. See [member block_color] for more information.
@export_color_no_alpha var command_color:Color:
	set(value): return
	get: return _get_color()

## Command category where this command be grouped with
## in editor.
@export var command_category:StringName:
	set(value): return
	get: return _get_category()

@export_group("")

## [CommandProcessor] node that is executing this command.
## This value is assigned by its current command manager and
## should not be assigned manually.
var command_manager:Node

#endregion

#region BLOCK DATA

## What color to paint this command with.
## Purely visual!
## @deprecated: Use [member block_color] instead.
@export_enum("Blank", "Red", "Yellow", "Green", "Aqua", "Blue", "Purple", "Pink") var background_color:int:
	set(value):
		background_color = value
		emit_changed()
	get: return background_color

## Command hint icon. Use [method _get_hint_icon] to define the texture.
## [br]This texture will be displayed before [member command_hint].
## [codeblock]
## func _get_hint_icon() -> Texture:
##     return load("res://icon.svg")
## [/codeblock]
## @deprecated: Use [member block_icon] instead.
var command_hint_icon:Texture :
	set(value): return
	get: return _get_hint_icon()

## The color of this command's text
## Used by the Comment command to fade the text out
## @deprecated
var command_text_color:Color :
	set(value): return
	get: return _get_color()

@export_group(&"Block", &"block_")
## Used as [member command_name] alias. Defined value will replace
## the text displayed in the block representation.
@export var block_name:String:
	set(value):
		if block_name == value:
			return
		block_name = value
		emit_changed()

## Color used to tint the vertical bar and background of the
## block representation.[br]
## Possible values are:[br]
## [color=red]- Red [/color][br]
## [color=yellow]- Yellow[/color][br]
## [color=green]- Green[/color][br]
## [color=aqua]- Aqua[/color][br]
## [color=blue]- Blue[/color][br]
## [color=purple]- Purple[br][/color]
## [color=pink]- Pink[br][/color]
## - Custom[br]
## If [code]Custom[/code] is selected, you can define a custom color
## value with [member block_custom_color].[br]
## All values, except [code]Custom[/code] will be automatically
## adjusted according their background.
@export var block_color:int:
	set(value):
		if block_color == value:
			return
		block_color = value
		emit_changed()
		notify_property_list_changed()

## Color used to tint the vertical bar and background of the
## block representation.[br]
## This value is used when [member block_color] value is 
## [code]Custom (8)[/code].
@export var block_custom_color:Color:
	set(value):
		if block_custom_color == value:
			return
		block_custom_color = value
		emit_changed()

## Texture icon used in the block representation.
@export var block_icon:Texture:
	set(value):
		if block_icon == value:
			return
		block_icon = value
		emit_changed()

## Custom [Block] scene used in editor.[br]
## This scene must extend [Block] and must be `@tool`
@export var block_custom_scene:PackedScene:
	set(value):
		if block_custom_scene == value:
			return
		block_custom_scene = value
		emit_changed()

## [CommandBlock] item assigned by editor.
## [br]This reference is assigned by Block Editor.
var editor_block:Object

## Layout data used by editor. This data is saved in editor
## and is not shared between projects.
var editor_state:Dictionary
#endregion

## Execution steps that will be called to execute the command behaviour.
## By default, it uses [method _execution_steps], you can override
## that method to define your own steps.
var execution_steps:Callable = _execution_steps

## Target node that [member target] points to. This value is assigned by
## [member command_manager] before command execution if [member target] is a
## valid path, else node assigned in
## [member CommandProcessor.command_node_fallback_path] is used instead.
var target_node:Node

## Current command position in the collection.
## Index is determined by its [member weak_owner]
## and should not be set during runtime.
var index:int = -1

## Command position determined by [member weak_collection]
var position:int = -1

## Specify if this command can hold commands as if they
## were subcommands.
## If [code]true[/code] enables
## the option to drop commands on this command
## to handle them as subcommands in Block Editor.
##
##[br][br]Use [method _can_hold_commands] to define the value.
## [codeblock]
## func _can_hold_commands() -> bool:
##     return true
## [/codeblock]
var can_hold_commands:bool :
	set(value): return
	get: return _can_hold_commands()

## Specify if this command can hold branches.
##
##[br][br]If [code]true[/code] enables
## the option to create branches on this command
## according to [method _get_default_branch_names].
##
##[br][br]Use [method _defines_default_branches] to define the value.
## [codeblock]
## func _defines_default_branches() -> bool:
##     return true
## [/codeblock]
## @deprecated: Property defines a non supported behavior
var defines_default_branches:bool:
	set(value): return
	get: return _defines_default_branches()

## Specify if this command can be moved in editor after
## creation. Used mainly by custom [constant Branch] commands.
##
##[br][br]Use [method _can_be_moved] to define the value.
## [codeblock]
## func _can_be_moved() -> bool:
##     return true
## [/codeblock]
## @deprecated: This is block_ related but is unused
var can_be_moved:bool :
	set(value): return
	get: return _can_be_moved()

## Specify if this command can be selected in editor.
## If value is [code]false[/code], user will not be able
## to select and inspect the command block in Block Editor.
##
##[br][br]Use [method _can_be_selected] to define the value.
## [codeblock]
## func _can_be_selected() -> bool:
##     return true
## [/codeblock]
## @deprecated: This is block_ related but is unused
var can_be_selected:bool :
	set(value): return
	get: return _can_be_selected()


## Returns the assigned [CommandCollection]. See [member Collection.weak_collection]
## for possible values.
func get_main_collection() -> Blockflow.CommandCollectionClass:
	if weak_collection:
		return weak_collection.get_ref() as Blockflow.CommandCollectionClass
	return null

## Returns the assigned [Collection]. See [member Collection.weak_owner] for possible values.
func get_command_owner() -> Collection:
	if weak_owner:
		return weak_owner.get_ref() as Collection
	return null

## Get the next command position.
func get_next_command_position() -> int:
	return position + 1

## Get the next command index.
func get_next_command_index() -> int:
	return index + 1

## Get the next command according [method get_next_command_position] on
## [method get_main_collection].
func get_next_command() -> Command:
	var main_collection := get_main_collection()
	if not main_collection:
		push_error("!main_collection")
		return null
	
	if get_next_command_position() >= main_collection.get_command_count():
		return null
	
	return main_collection.get_command(get_next_command_position())

## Get the next available command. This is the next command to this
## command according [method get_next_command_index] on
## [method get_command_owner]
func get_next_available_command() -> Command:
	var owner := get_command_owner()
	if not owner:
		push_error("!owner")
		return null
	
	if get_next_command_index() >= owner.size():
		return null
	
	return owner.collection[get_next_command_index()]

## Request [member command_manager] go to the next available command.
## [br][member command_manager] will go to the next subcommand if there's any.
## It will not use a branch as the next command. Use
## [method go_to_branch] instead.
func go_to_next_command() -> void:
	command_finished.emit()

## Request [member command_manager] to go to a specific
## [param command_position] command in the main collection.
##
## [br][br]Note: Calling this method will not trigger 
## [signal command_finished] and will go to the requested
## [param command_position] inmediatly.
func go_to_command(command_position:int) -> void:
	command_manager.jump_to_command(command_position, null)

## Request [member command_manager] to go to a specific branch defined in
## [member branches].
## [param branch] can be:
## [br]  - [String] value, it'll match any branch with that name,
## branch names must be unique or it'll use last match
## [br]  - [int] value, it'll use the branch according 
## [member branches.get_command]
## @deprecated
func go_to_branch(branch) -> void:
	assert(false, "Not implemented")
	return

## Stops [member command_manager] processing.
func stop() -> void:
	command_manager.stop()
	go_to_next_command()

func is_branch() -> bool:
	return is_instance_of(self, Branch)

func is_subcommand() -> bool:
	return get_command_owner() != null

## Called by editor.
##[br][br]Acts as a filter to know what types of commands this command can hold.
## This does not forces the collection accept only that type of commands and
## only serves as guide to block editor.
func can_hold(command) -> bool:
	return can_hold_commands

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

## @deprecated
func _get_hint_icon() -> Texture:
	return null

## @deprecated
func _can_be_moved() -> bool:
	return true

## @deprecated
func _can_be_selected() -> bool:
	return true

func _get_description() -> String:
	return ""

func _get_color() -> Color:
	return Color()

func _get_category() -> StringName:
	return &"Commands"

func _can_hold_commands() -> bool:
	return false

## @deprecated
func _defines_default_branches() -> bool:
	return false

## @deprecated
func _get_default_branch_names() -> PackedStringArray:
	return []

## @deprecated: This function is unused and will be removed in future versions.
func _get_default_branch_for(branch_name:StringName) -> Branch:
	var branch := Branch.new()
	branch.branch_name = branch_name
	return branch

## Changes a variable of the target node.
## @experimental
func _add_variable(varname: String, vartype, varvalue, target_node: Node):
	if varname in target_node:
		target_node.set(varname, varvalue)
		return
	target_node.set_meta(varname, varvalue)

## Removes a variable from the target node. NOTE: This is currently [b]unused[/b]
## This function has the side effect of preventing [code]_add_variable[/code] from setting the original if the variable was originally part of the node.
## @experimental
func _remove_variable(varname):
	if target_node.is_instance_valid(varname) != null:
		target_node.set(varname, null)
		return
	target_node.set_meta(varname, null)

# TODO: This is not needed yet
## @experimental
func _add_signal(signalname: String, signalconnections, target_node):
	pass
	
# TODO: This is not needed yet, and I don't know how to implement it :shrug:
## @experimental
func _remove_signal(signalname):
	pass

# TODO: This is not needed yet
## @experimental
func _add_function(funcname, funcargs, funcblocks,):
	pass

# TODO: This is not needed yet
## @experimental
func _remove_function(funcname,):
	pass

func _to_string() -> String:
	return "<%s [%s:%s] # %d>" % [command_name,position,index, get_instance_id()]

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		if collection.is_empty() and defines_default_branches:
			# For some reason the collection is empty but
			# command defines default branches.
			# Maybe is the first time this command is created?
			for branch_name in _get_default_branch_names():
				collection.append(_get_default_branch_for(branch_name))
	
		for command_index in collection.size():
			var command:Command = collection[command_index]
			command.weak_owner = weakref(self)
			command.index = command_index
			
			# Verify branch
			if defines_default_branches:
				if command.is_branch() and\
				command.command_name in _get_default_branch_names():
					var branch:Branch = _get_default_branch_for(command.command_name)
					print("???")
					if not is_instance_of(command, branch.get_script()):
						# Old branch is not the same type as the defined in
						# default branches. Update it, preserving subcommands.
						branch.weak_owner = command.weak_owner
						branch.index = command.index
						branch.collection = command.collection
						collection.remove_at(command_index)
						collection.insert(command_index, branch)


func _set(property: StringName, value: Variant) -> bool:
	return false


func _get(property: StringName):
	match property:
		#region debug
		&"debug/position":
			return position
		&"debug/index":
			return index
		&"debug/owner":
			return weak_owner
			return get_command_owner()
		&"debug/main_collection":
			return weak_collection
			return get_main_collection()
		#endregion

func _property_can_revert(property: StringName) -> bool:
	return property.begins_with(&"block_")

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"block_name":
			return ""
		&"block_color":
			return 0
		&"block_custom_color":
			return Color()
		&"block_icon":
			return null
	return

func _validate_property(property: Dictionary) -> void:
	super(property)
	
	var property_name:StringName = property.get(&"name", &"")
	
	if property_name.begins_with(&"command_"):
		const cmd_data = [
			&"command_name",
			&"command_icon",
			&"command_description",
			&"command_hint",
			&"command_category",
		]
		if not property_name in cmd_data: return
		
		property[&"usage"] = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
		return
	
	match property_name:
		&"resource_local_to_scene", &"resource_path", &"resource_name", &"script":
			property[&"usage"] |= PROPERTY_USAGE_READ_ONLY
			return
		
		&"block_name":
			property[&"hint"] = PROPERTY_HINT_PLACEHOLDER_TEXT
			property[&"hint_string"] = command_name
			
			if block_name.is_empty():
				property[&"usage"] = PROPERTY_USAGE_EDITOR
			else:
				property[&"usage"] = PROPERTY_USAGE_DEFAULT
		
		&"block_color":
			property[&"hint"] = PROPERTY_HINT_ENUM
			property[&"hint_string"] = "[None],Red,Yellow,Green,Aqua,Blue,Purple,Pink,Custom"
			
			if block_color <= 0:
				property[&"usage"] = PROPERTY_USAGE_EDITOR
			else:
				property[&"usage"] = PROPERTY_USAGE_DEFAULT
			
		&"block_custom_color":
			property[&"hint"] = PROPERTY_HINT_COLOR_NO_ALPHA
			
			if block_color < 8:
				property[&"usage"] = PROPERTY_USAGE_NONE
			else:
				property[&"usage"] = PROPERTY_USAGE_DEFAULT

func _get_property_list() -> Array[Dictionary]:
	var p:Array[Dictionary] = []
	
	if OS.is_stdout_verbose():
		p.append({
			&"name":&"debug/position",
			&"type":TYPE_INT,
			&"usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY,
		})
		p.append({
			&"name":&"debug/index",
			&"type":TYPE_INT,
			&"usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY
		})
		p.append({
			&"name":&"debug/owner",
			&"type":TYPE_OBJECT,
			&"usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY,
		})
		p.append({
			&"name":&"debug/main_collection",
			&"type":TYPE_OBJECT,
			&"usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY,
		})
	return p

func _get_editor_name():
	return block_name if not(block_name.is_empty()) else command_name
