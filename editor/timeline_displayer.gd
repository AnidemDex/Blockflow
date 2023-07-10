@tool
extends Tree

const TimelineClass = preload("res://addons/blockflow/timeline.gd")
const EditorCommand = preload("res://addons/blockflow/editor/editor_command/editor_command.gd")
const EditorCommandRoot = preload("res://addons/blockflow/editor/editor_command/editor_command_root.gd")
const FALLBACK_ICON = preload("res://icon.svg")
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")


var _current_timeline:TimelineClass

var root:EditorCommandRoot

func load_timeline(timeline:TimelineClass) -> void:
	_current_timeline = timeline
	_reload()


func _reload() -> void:
	clear()
	
	if not _current_timeline:
		return
	
	set_column_custom_minimum_width(0, 164)
	
	var r:TreeItem = create_item()
	r.set_script(EditorCommandRoot)
	root = r as EditorCommandRoot
	root.timeline = _current_timeline
	
#	for i in columns:
#		root.set_expand_right(i, false)
	# See this little trick here? Is to remove the column expand.
	# I hate it.
	#root.set_text(columns-1, " ")
	var commands:Array = _current_timeline.commands 
	for command_idx in commands.size():
		var itm:TreeItem = create_item(root)
		itm.set_script(EditorCommand)
		var item:EditorCommand = itm as EditorCommand
		var command:Command = commands[command_idx] as Command
		
		if not command:
			assert(command)
			load_timeline(null)
			return
		
		item.command = command
	
	root.call_recursive("update")


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

