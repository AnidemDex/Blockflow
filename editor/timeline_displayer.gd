@tool
extends Tree

const TimelineClass = preload("res://addons/blockflow/timeline.gd")
const CommandBlock = preload("res://addons/blockflow/editor/command_block/block.gd")
const RootBlock = preload("res://addons/blockflow/editor/command_block/root.gd")
const FALLBACK_ICON = preload("res://icon.svg")
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")


var _current_timeline:TimelineClass

var root:RootBlock
var displayed_commands:Array = []

func load_timeline(timeline:TimelineClass) -> void:
	_current_timeline = timeline
	_reload()


func _reload() -> void:
	clear()
	displayed_commands.clear()
	
	if not _current_timeline:
		return
	
	set_column_custom_minimum_width(0, 164)
	
	var r:TreeItem = create_item()
	r.set_script(RootBlock)
	root = r as RootBlock
	root.timeline = _current_timeline
	
#	for i in columns:
#		root.set_expand_right(i, false)
	# See this little trick here? Is to remove the column expand.
	# I hate it.
	#root.set_text(columns-1, " ")
	var commands:Array = _current_timeline.commands.collection
	var subcommand:Array = []
	
	for command_idx in commands.size():
		var command:Command = commands[command_idx] as Command
		if not command:
			assert(command)
			load_timeline(null)
			return
		var parent:CommandBlock = root
		
		_add_command(command, parent)
		
	root.call_recursive("update")

func _add_command(command:Command, under_block:CommandBlock) -> void:
	if command in displayed_commands:
		assert(false)
		return
	if not command:
		assert(false)
		return
	var itm:TreeItem = create_item(under_block)
	itm.set_script(CommandBlock)
	var block:CommandBlock = itm as CommandBlock
	block.command = command
	command.editor_block = block
	
	displayed_commands.append(command)
	if not command.branches.is_empty():
		for branch in command.branches:
			_add_command(branch, block)
	
	if not command.commands.is_empty():
		for subcommand in command.commands:
			_add_command(subcommand, block)


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
	columns = CommandBlock.ColumnPosition.size()
	allow_rmb_select = true
	select_mode = SELECT_ROW
	scroll_horizontal_enabled = false
	
	set_column_expand(0, false)
	set_column_expand(1, true)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(2, 64)
	
	item_edited.connect(_on_item_edited)

