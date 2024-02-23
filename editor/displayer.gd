@tool
extends Tree

const Blockflow = preload("res://addons/blockflow/blockflow.gd")
const CollectionClass = preload("res://addons/blockflow/command_collection.gd")

const CommandBlock = preload("res://addons/blockflow/editor/command_block/block.gd")
const RootBlock = preload("res://addons/blockflow/editor/command_block/root.gd")

const FALLBACK_ICON = preload("res://addons/blockflow/icons/false.svg")
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")

var last_selected_command:Blockflow.CommandClass

var _current_collection:CollectionClass

var root:RootBlock
var displayed_commands:Array = []

func build_tree(object:Object) -> void:
	var collection:CollectionClass
	if object is Blockflow.TimelineClass:
		collection = object.get_collection_equivalent()
	else:
		collection = object as CollectionClass
	
	_current_collection = collection
	last_selected_command = null
	_reload()


func _reload() -> void:
	clear()
	
	displayed_commands = []
	
	if not _current_collection:
		last_selected_command = null
		return
	
	var min_width:int = 24 + Blockflow.BLOCK_ICON_MIN_SIZE
	set_column_custom_minimum_width(CommandBlock.ColumnPosition.NAME_COLUMN, min_width*columns)
	set_column_custom_minimum_width(CommandBlock.ColumnPosition.INDEX_COLUMN, 42)
	
	var r:TreeItem = create_item()
	r.set_script(RootBlock)
	root = r as RootBlock
	root.collection = _current_collection
	
	var commands:Array = _current_collection.collection
	var subcommand:Array = []
	
	for command in _current_collection:
		_add_command(command, root)
	
	root.call_recursive("update")
	if last_selected_command and is_instance_valid(last_selected_command.editor_block):
		last_selected_command.editor_block.select(0)
	else:
		last_selected_command = null
	

func _add_command(command:Blockflow.CommandClass, under_block:CommandBlock) -> void:
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
	for subcommand in command:
		_add_command(subcommand, block)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		if get_selected() == root:
			assert(false, "Editing through double click is not implemented")
			accept_event()


func _on_item_edited() -> void:
	if get_selected() == root:
		_current_collection.resource_name = root.get_text(0)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			set_column_expand(CommandBlock.ColumnPosition.NAME_COLUMN, false)
			set_column_expand(CommandBlock.ColumnPosition.HINT_COLUMN, true)
			set_column_expand(CommandBlock.ColumnPosition.BUTTON_COLUMN, false)
			set_column_expand(CommandBlock.ColumnPosition.INDEX_COLUMN, false)
			
			set_column_clip_content(
				CommandBlock.ColumnPosition.NAME_COLUMN,
				false
			)
			
			set_column_clip_content(
				CommandBlock.ColumnPosition.HINT_COLUMN,
				true
			)
			
			set_column_clip_content(
				CommandBlock.ColumnPosition.INDEX_COLUMN,
				false
			)


func _init() -> void:
	# Allows multiple column stuff without manually change
	columns = CommandBlock.ColumnPosition.size()
	allow_rmb_select = true
	select_mode = SELECT_ROW
	scroll_horizontal_enabled = false
	
	item_edited.connect(_on_item_edited)

