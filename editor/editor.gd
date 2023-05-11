@tool
extends PanelContainer

const TimelineDisplayer = preload("res://addons/blockflow/editor/timeline_displayer.gd")
const CommandList = preload("res://addons/blockflow/command_list.gd")

enum _ItemPopup {
	MOVE_UP, 
	MOVE_DOWN, 
	DUPLICATE,
	REMOVE,
	}

enum _DropSection {
	NO_ITEM = -100, 
	ABOVE_ITEM = -1,
	IN_ITEM,
	UNDER_ITEM,
	}

enum ToolbarFileMenu {
	NEW_TIMELINE,
	OPEN_TIMELINE,
	CLOSE_TIMELINE,
}

var undo_redo:UndoRedo:
	set(value):
		undo_redo = value
	get:
		if not is_instance_valid(undo_redo):
			undo_redo = UndoRedo.new()
			tree_exited.connect(Callable(undo_redo, "free"))
			push_warning("TimelineEditor: Using custom UndoRedo.")
		
		return undo_redo

var editor_undoredo:EditorUndoRedoManager

var timeline_displayer:TimelineDisplayer
var command_list:CommandList
var title_label:Label
var edit_callback:Callable

var _current_timeline:Timeline

var _item_popup:PopupMenu
var _moving_command:bool = false

var _help_panel:Container
var _help_panel_new_btn:Button
var _help_panel_load_btn:Button
var _help_panel_label:Label

var _toolbar:MenuBar
var _file_menu:PopupMenu

var _editor_file_dialog:EditorFileDialog

func edit_timeline(timeline:Timeline) -> void:
	var load_function:Callable = timeline_displayer.load_timeline
	var path_hint:String = ""
	
	if _current_timeline:
		if _current_timeline.changed.is_connected(load_function):
			_current_timeline.changed.disconnect(load_function)
	
	_current_timeline = timeline
	
	if _current_timeline:
		if not timeline.changed.is_connected(load_function):
			timeline.changed.connect(load_function.bind(timeline), CONNECT_DEFERRED)
		path_hint = _current_timeline.resource_path
		hide_help_panel()
		_file_menu.set_item_disabled(_file_menu.get_item_index(ToolbarFileMenu.CLOSE_TIMELINE), false)
	else:
		_file_menu.set_item_disabled(_file_menu.get_item_index(ToolbarFileMenu.CLOSE_TIMELINE), true)
		show_help_panel()
	
	title_label.text = path_hint
	load_function.call(timeline)


func add_command(command:Command, at_position:int = -1) -> void:
	if not _current_timeline: return
	if not command: return
	
	var action_name:String = "Add command '%s'" % [command.get_command_name()]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		
		if at_position < 0:
			editor_undoredo.add_do_method(_current_timeline, "add_command", command)
		else:
			editor_undoredo.add_do_method(_current_timeline, "insert_command", command, at_position)
		
		editor_undoredo.add_undo_method(_current_timeline, "erase_command", command)
		editor_undoredo.commit_action()
		
	else:
		undo_redo.create_action(action_name)
		
		if at_position < 0:
			undo_redo.add_do_method(_current_timeline.add_command.bind(command))
		else:
			undo_redo.add_do_method(_current_timeline.insert_command.bind(command, at_position))
		
		undo_redo.add_undo_method(_current_timeline.erase_command.bind(command))
		
		undo_redo.commit_action()


func move_command(command:Command, to_position:int) -> void:
	if not _current_timeline: return
	if not command: return
	
	var old_position:int = _current_timeline.get_command_idx(command)
	var action_name:String = "Move command '%s'" % [command.get_command_name()]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(_current_timeline, "move_command", command, to_position)
		editor_undoredo.add_undo_method(_current_timeline, "move_command", command, old_position)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(_current_timeline.move_command.bind(command, to_position))
		undo_redo.add_undo_method(_current_timeline.move_command.bind(command, old_position))
		
		undo_redo.commit_action()


func duplicate_command(command:Command, to_position:int) -> void:
	if not _current_timeline: return
	if not command: return
	
	var at_position:int = _current_timeline.get_command_idx(command)
	var action_name:String = "Duplicate command '%s'" % [command.get_command_name()]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(_current_timeline, "duplicate_command", command, to_position)
		editor_undoredo.add_undo_method(_current_timeline, "erase_command", command)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(_current_timeline.duplicate_command.bind(command, to_position))
		undo_redo.add_undo_method(_current_timeline.erase_command.bind(command))
		
		undo_redo.commit_action()


func remove_command(command:Command) -> void:
	if not _current_timeline: return
	if not command: return
	
	var command_idx:int = _current_timeline.get_command_idx(command)
	var action_name:String = "Remove command '%s'" % [command.get_command_name()]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(_current_timeline, "remove_command", command_idx)
		editor_undoredo.add_undo_method(_current_timeline, "insert_command", command, command_idx)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(_current_timeline.remove_command.bind(command_idx))
		undo_redo.add_undo_method(_current_timeline.insert_command.bind(command, command_idx))
		
		undo_redo.commit_action()


func show_help_panel():
	_help_panel.show()


func hide_help_panel():
	_help_panel.hide()


func _request_load_timeline() -> void:
	_editor_file_dialog.current_dir = ""
	_editor_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_editor_file_dialog.filters = ["*.tres, *.res ; Resource file"]
	_editor_file_dialog.title = "Load Timeline"
	_editor_file_dialog.popup_centered_ratio(0.5)


func _request_new_timeline() -> void:
	_editor_file_dialog.current_dir = ""
	_editor_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_editor_file_dialog.filters = ["*.tres, *.res ; Resource file"]
	_editor_file_dialog.title = "New Timeline"
	_editor_file_dialog.popup_centered_ratio(0.5)


func _item_popup_id_pressed(id:int) -> void:
	var command:Command = timeline_displayer.get_selected().get_metadata(0)
	var command_idx:int = _current_timeline.get_command_idx(command)
	match id:
		_ItemPopup.MOVE_UP:
			move_command(command, max(0, command_idx - 1))
			
		_ItemPopup.MOVE_DOWN:
			move_command(command, command_idx + 1)

		_ItemPopup.DUPLICATE:
			duplicate_command(command, command_idx + 1)
			
		_ItemPopup.REMOVE:
			remove_command(command)


func _command_button_list_pressed(command_script:Script) -> void:
	var command:Command = command_script.new()
	add_command(command)


func _timeline_displayer_item_mouse_selected(_position:Vector2, button_index:int) -> void:
	if button_index == MOUSE_BUTTON_RIGHT:
		_item_popup.clear()
		_item_popup.add_item("Move up", _ItemPopup.MOVE_UP)
		_item_popup.add_item("Move down", _ItemPopup.MOVE_DOWN)
		_item_popup.add_separator()
		_item_popup.add_item("Duplicate", _ItemPopup.DUPLICATE)
		_item_popup.add_item("Remove", _ItemPopup.REMOVE)
		
		_item_popup.reset_size()
		_item_popup.position = DisplayServer.mouse_get_position()
		_item_popup.popup()


func _timeline_displayer_item_selected() -> void:
	if edit_callback.is_null():
		push_error("TimelineEditor: No edit callback was defined.")
		return
	
	var selected_command = timeline_displayer.get_selected().get_metadata(0)
	edit_callback.bind(selected_command).call_deferred()


func _timeline_displayer_get_drag_data(at_position: Vector2):
	var item:TreeItem = timeline_displayer.get_item_at_position(at_position)

	if not item:
		return null

	var drag_data = {"type":"resource", "resource":null, "from":self}
	drag_data["resource"] = item.get_metadata(0)
	
	if not drag_data["resource"]:
		return null
	
	var drag_preview = Button.new()
	drag_preview.text = (drag_data.resource as Command).get_command_name()
	set_drag_preview(drag_preview)
	
	return drag_data


func _timeline_displayer_can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var ref_item:TreeItem = timeline_displayer.get_item_at_position(at_position)
	var ref_res:Resource = data.get("resource")
	if ref_item and ref_item.get_metadata(0) == ref_res:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	if ref_item == timeline_displayer.root:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
	else:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	
	var command:Command = (data as Dictionary).get("resource") as Command
	if command:
		return true
	
	return false


func _timeline_displayer_drop_data(at_position: Vector2, data) -> void:
	var section:int = timeline_displayer.get_drop_section_at_position(at_position)
	var command:Command = data["resource"]
	var ref_item:TreeItem = timeline_displayer.get_item_at_position(at_position)
	var cmd_idx:int = _current_timeline.get_command_idx(command)
	var ref_idx:int = NAN if not ref_item else ref_item.get_index()

	match section:
		_DropSection.NO_ITEM:
			move_command(command, -1)
		
		_DropSection.ABOVE_ITEM:
			if ref_idx != NAN:
				move_command(command, ref_idx - int(ref_idx >= cmd_idx))
		
		_DropSection.IN_ITEM, _DropSection.UNDER_ITEM:
			if ref_item == timeline_displayer.root:
				move_command(command, 0)
				return
			if ref_idx != NAN:
				move_command(command, ref_idx + int(ref_idx < cmd_idx))


func _editor_file_dialog_file_selected(path:String) -> void:
	var timeline:Timeline
	
	if _editor_file_dialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		timeline = Timeline.new()
		timeline.resource_name = path.get_file()
		
		var err:int = ResourceSaver.save(timeline, path)
		if err != 0:
			push_error("Saving timeline failed with Error '%s'" % err)
			return
		timeline = load(path)
	
	timeline = load(path) as Timeline
	
	if not timeline:
		push_error("TimelineEditor: '%s' is not a valid Timeline" % path)
		return
	
	edit_callback.bind(timeline).call_deferred()


func _toolbar_file_menu_id_pressed(id:int) -> void:
	match id:
		ToolbarFileMenu.NEW_TIMELINE:
			_request_new_timeline()
		ToolbarFileMenu.OPEN_TIMELINE:
			_request_load_timeline()
		ToolbarFileMenu.CLOSE_TIMELINE:
			edit_timeline(null)
			edit_callback.get_object().call("edit_node", null)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			_help_panel_load_btn.icon = get_theme_icon("Object", "EditorIcons")
			_help_panel_new_btn.icon = get_theme_icon("Load", "EditorIcons")
			title_label.add_theme_stylebox_override("normal", get_theme_stylebox("ContextualToolbar", "EditorStyles"))


func _init() -> void:
	name = "TimelineEditor"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vb)
	
	_item_popup = PopupMenu.new()
	_item_popup.name = "ItemPopup"
	_item_popup.allow_search = false
	_item_popup.id_pressed.connect(_item_popup_id_pressed, CONNECT_DEFERRED)
	add_child(_item_popup)
	
	_toolbar = MenuBar.new()
	_toolbar.flat = true
	vb.add_child(_toolbar)
	
	_file_menu = PopupMenu.new()
	_file_menu.allow_search = false
	_file_menu.id_pressed.connect(_toolbar_file_menu_id_pressed)
	_file_menu.add_item("New Timeline...", ToolbarFileMenu.NEW_TIMELINE)
	_file_menu.add_item("Open Timeline...", ToolbarFileMenu.OPEN_TIMELINE)
	_file_menu.add_separator()
	_file_menu.add_item("Close current timeline", ToolbarFileMenu.CLOSE_TIMELINE)
	_file_menu.set_item_disabled(_file_menu.get_item_index(ToolbarFileMenu.CLOSE_TIMELINE), true)
	_toolbar.add_child(_file_menu)
	
	_toolbar.set_menu_title(0, "File")
	
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title_label)
	
	var hb:HBoxContainer = HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	
	command_list = CommandList.new()
	command_list.name = "CommandList"
	command_list.command_button_list_pressed = _command_button_list_pressed
	hb.add_child(command_list)
	
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_child(pc)
	
	timeline_displayer = TimelineDisplayer.new()
	timeline_displayer.name = "TimelineDisplayer"
	timeline_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_displayer.item_mouse_selected.connect(_timeline_displayer_item_mouse_selected)
	timeline_displayer.item_selected.connect(_timeline_displayer_item_selected)
	timeline_displayer.set_drag_forwarding(_timeline_displayer_get_drag_data, _timeline_displayer_can_drop_data, _timeline_displayer_drop_data)
	pc.add_child(timeline_displayer)
	
	_help_panel = PanelContainer.new()
	_help_panel.name = "HelpPanel"
	_help_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_help_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.add_child(_help_panel)
	
	vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_help_panel.add_child(vb)
	
	_help_panel_label = Label.new()
	_help_panel_label.text = "You're not editing any timeline."
	_help_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_help_panel_label)
	
	hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	
	_help_panel_new_btn = Button.new()
	_help_panel_new_btn.text = "New Timeline"
	_help_panel_new_btn.pressed.connect(_request_new_timeline)
	hb.add_child(_help_panel_new_btn)
	
	_help_panel_load_btn = Button.new()
	_help_panel_load_btn.text = "Load Timeline"
	_help_panel_load_btn.pressed.connect(_request_load_timeline)
	hb.add_child(_help_panel_load_btn)
	
	show_help_panel()
	
	_editor_file_dialog = EditorFileDialog.new()
	_editor_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
	add_child(_editor_file_dialog)
	
