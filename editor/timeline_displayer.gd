@tool
extends Tree

const TimelineClass = preload("res://addons/blockflow/timeline.gd")
const EditorCommand = preload("res://addons/blockflow/editor/editor_command/editor_command.gd")
const EditorCommandRoot = preload("res://addons/blockflow/editor/editor_command/editor_command_root.gd")
const EditorSubcommand = preload("res://addons/blockflow/editor/editor_command/editor_subcommand.gd")
const FALLBACK_ICON = preload("res://icon.svg")
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")


var _current_timeline:TimelineClass

var root:EditorCommandRoot

## { <Command> | name : [sub_command, ...] | {} }
var command_struct:Dictionary = {}

func load_timeline(timeline:TimelineClass) -> void:
	_current_timeline = timeline
	_reload()


func _reload() -> void:
	clear()
	command_struct = {}
	
	if not _current_timeline:
		return
	
	set_column_custom_minimum_width(0, 164)
	
	var r:TreeItem = create_item()
	r.set_script(EditorCommandRoot)
	root = r as EditorCommandRoot
	root.timeline = _current_timeline
	root.update()
	
#	for i in columns:
#		root.set_expand_right(i, false)
	# See this little trick here? Is to remove the column expand.
	# I hate it.
	#root.set_text(columns-1, " ")
	var commands:Array = _current_timeline.commands 
	for command_idx in commands.size():
		var command:Command = commands[command_idx] as Command
		_add_command(command, root)


func _add_command(command:Command, as_child_of:TreeItem) -> void:
	if command.editor_treeitem != null:
		# Avoid re-creating TreeItem
		# But why there would be an item? Sounds like a bug
		return
	
	var itm:TreeItem = create_item(as_child_of)
	itm.set_script(EditorCommand)
	var item:EditorCommand = itm as EditorCommand
	
	if not command:
		assert(command)
		load_timeline(null)
		return
	
	item.command = command
	command.editor_treeitem = item # Cross-referencing stuff huh?
	item.update()
	
	if command.uses_subcommands():
		_handle_subcommands_for(command)


func _handle_subcommands_for(command:Command) -> void:
	assert(command.editor_treeitem, "EDITORCOMMAND_ITEM_DOESNT_EXIST")
	
	# Time to overcomplicate stuff
	# I'm all ears if anyone has a better idea.
	if command._subcommands_quantity_property().is_empty():
		push_error("NOT_DEFINED_QUANTITY_PROPERTY")
		return
	
	# Check for those that doesn't implement custom subcommands
	# This means the command will add subcommands under it directly
	if command.get_custom_subcommands().is_empty():
		if not command_struct.has(command):
			command_struct[command] = []
		
		var subcommand_quantity = command._subcommands_quantity_property()[0]
		for i in range(1, subcommand_quantity+1):
			var _next_command = _current_timeline.get_command(command.index+i)
			if not command_struct[command].has(_next_command):
				command_struct[command].append(_next_command)
	
	# Seems like it implements custom subcommands.
	# These are fancy commands that exist only in editor, and the real
	# subcommands are added under them.
	else:
		if not command_struct.has(command):
			command_struct[command] = {}
		
		for subcmd_idx in command.get_custom_subcommands().size():
			var subcommand_name:String = command.get_custom_subcommands()[subcmd_idx]
			
			if not command_struct[command].has(subcommand_name):
				command_struct[command][subcommand_name] = []
			
			var subcommand_struct:Array = command_struct[command][subcommand_name]
			var subcommand_quantity_property:String = command._subcommands_quantity_property()[subcmd_idx]
			var subcommand_quantity:int = command.get(subcommand_quantity_property)
			for i in range(1, subcommand_quantity+1):
				var _next_command = _current_timeline.get_command(command.index+i)
				if not subcommand_struct.has(_next_command):
					subcommand_struct.append(_next_command)
		
		match typeof(command_struct[command]):
			TYPE_ARRAY:
				for subcommand in command_struct[command]:
					_add_command(subcommand, command.editor_treeitem)
			
			TYPE_DICTIONARY:
				for subcommand_name in command_struct[command].keys():
					var item:EditorCommand = command.editor_treeitem
					var child = item.create_child()
					child.set_script(EditorSubcommand)
					var subcommand_item:EditorSubcommand = child as EditorSubcommand
					subcommand_item.label = subcommand_name
					subcommand_item.subcommands = command_struct[command][subcommand_name]
					
					for subcommand in command_struct[command][subcommand_name]:
						_add_command(subcommand, subcommand_item)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		if get_selected() == root:
			edit_selected()
			accept_event()


func _on_item_edited() -> void:
	if get_selected() == root:
		_current_timeline.resource_name = root.get_text(0)


func _init() -> void:
	# Allows multiple column stuff without manually change
	columns = EditorCommand.ColumnPosition.size()
	allow_rmb_select = true
	select_mode = SELECT_ROW
	scroll_horizontal_enabled = false
	
	set_column_expand(0, false)
	set_column_expand(1, true)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(2, 64)
	
	item_edited.connect(_on_item_edited)

