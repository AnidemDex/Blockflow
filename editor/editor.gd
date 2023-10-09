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
	ON_ITEM,
	BELOW_ITEM,
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
			push_warning("CollectionEditor: Using custom UndoRedo.")
		
		return undo_redo

var editor_undoredo:EditorUndoRedoManager

var timeline_displayer:TimelineDisplayer
var command_list:CommandList
var title_label:Label
var edit_callback:Callable

var _current_timeline:Collection

var _item_popup:PopupMenu
var _moving_command:bool = false

var _help_panel:Container
var _help_panel_new_btn:Button
var _help_panel_load_btn:Button
var _help_panel_label:Label

var _toolbar:MenuBar
var _file_menu:PopupMenu

var _editor_file_dialog:EditorFileDialog
var _file_dialog:FileDialog

func edit_timeline(timeline:Object) -> void:
	if timeline is Timeline:
		push_warning("Timeline is deprecated")
		return
	if not(timeline is CommandCollection): return
	
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

func add_command(command:Command, at_position:int = -1, to_collection:Collection = null) -> void:
	if not _current_timeline: return
	if not command: return
	if not to_collection:
		to_collection = _current_timeline
	
	
	var action_name:String = "Add command '%s'" % [command.command_name]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		
		if at_position < 0:
			editor_undoredo.add_do_method(to_collection, "add", command)
		else:
			editor_undoredo.add_do_method(to_collection, "insert", command, at_position)
		
		editor_undoredo.add_undo_method(to_collection, "erase", command)
		editor_undoredo.commit_action()
		
	else:
		undo_redo.create_action(action_name)
		
		if at_position < 0:
			undo_redo.add_do_method(to_collection.add.bind(command))
		else:
			undo_redo.add_do_method(to_collection.insert.bind(command, at_position))
		
		undo_redo.add_undo_method(to_collection.erase.bind(command))
		
		undo_redo.commit_action()


func move_command(command:Command, to_position:int, from_collection:Collection=null, to_collection:Collection=null) -> void:
	if not _current_timeline: return
	if not command: return
	if command.index == to_position: return
	if not from_collection:
		from_collection = command.weak_owner.get_ref()
	if not to_collection:
		to_collection = command.weak_owner.get_ref()
	
	var from_position:int = from_collection.get_command_position(command)
	var action_name:String = "Move command '%s'" % [command.command_name]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		if from_collection == to_collection:
			editor_undoredo.add_do_method(from_collection, "move", command, to_position)
			editor_undoredo.add_undo_method(from_collection, "move", command, from_position)
		else:
			editor_undoredo.add_do_method(from_collection, "erase", command)
			editor_undoredo.add_undo_method(from_collection, "insert", command, from_position)
			editor_undoredo.add_do_method(to_collection, "insert", command, to_position)
			editor_undoredo.add_undo_method(to_collection, "erase", command)
#		editor_undoredo.add_do_method(_current_timeline, "update")
#		editor_undoredo.add_undo_method(_current_timeline, "update")
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		if from_collection == to_collection:
			undo_redo.add_do_method(from_collection.move.bind(command, to_position))
			undo_redo.add_undo_method(from_collection.move.bind(command, from_position))
		else:
			undo_redo.add_do_method(from_collection.erase.bind(command))
			undo_redo.add_undo_method(from_collection.insert.bind(command, from_position))
			undo_redo.add_do_method(to_collection.insert.bind(command, to_position))
			undo_redo.add_undo_method(to_collection.erase.bind(command))
		undo_redo.add_do_method(_current_timeline.update)
		undo_redo.add_undo_method(_current_timeline.update)
		
		undo_redo.commit_action()


func duplicate_command(command:Command, to_position:int) -> void:
	if not _current_timeline: return
	if not command: return
	var command_collection:Collection
	if not command.weak_owner:
		push_error("!command.weak_owner")
		return
	command_collection = command.weak_owner.get_ref()
	if not command_collection:
		push_error("!command_collection")
		return
	
	var at_position:int = _current_timeline.get_command_position(command)
	var action_name:String = "Duplicate command '%s'" % [command.get_command_name()]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(command_collection, "copy", command, to_position)
		editor_undoredo.add_undo_method(command_collection, "erase", command)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(command_collection.copy.bind(command, to_position))
		undo_redo.add_undo_method(command_collection.erase.bind(command))
		
		undo_redo.commit_action()


func remove_command(command:Command) -> void:
	if not _current_timeline: return
	if not command: return
	var command_collection:Collection
	if not command.weak_owner:
		push_error("not command.weak_owner")
		return
	command_collection = command.weak_owner.get_ref()
	if not command_collection:
		push_error("not command_collection")
		return
	
	var command_idx:int = _current_timeline.get_command_position(command)
	var action_name:String = "Remove command '%s'" % [command.command_name]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(command_collection, "remove", command_idx)
		editor_undoredo.add_undo_method(command_collection, "insert", command, command_idx)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(command_collection.remove.bind(command_idx))
		undo_redo.add_undo_method(command_collection.insert.bind(command, command_idx))
		
		undo_redo.commit_action()


func show_help_panel():
	_help_panel.show()


func hide_help_panel():
	_help_panel.hide()


func _request_load_timeline() -> void:
	var __file_dialog := _get_file_dialog()
	__file_dialog.current_dir = ""
	__file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	__file_dialog.filters = ["*.tres, *.res ; Resource file"]
	__file_dialog.title = "Load Collection"
	__file_dialog.popup_centered_ratio(0.5)


func _request_new_timeline() -> void:
	var __file_dialog := _get_file_dialog()
	__file_dialog.current_dir = ""
	__file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	__file_dialog.filters = ["*.tres, *.res ; Resource file"]
	__file_dialog.title = "New CommandCollection"
	__file_dialog.popup_centered_ratio(0.5)


func _item_popup_id_pressed(id:int) -> void:
	var command:Command = timeline_displayer.get_selected().get_metadata(0)
	var command_idx:int = command.weak_owner.get_ref().get_command_position(command)
	match id:
		_ItemPopup.MOVE_UP:
			move_command(command, max(0, command_idx - 1))
			
		_ItemPopup.MOVE_DOWN:
			move_command(command, command_idx + 1)

		_ItemPopup.DUPLICATE:
			duplicate_command(command, command_idx + 1)
			
		_ItemPopup.REMOVE:
			remove_command(command)


func _get_file_dialog() -> ConfirmationDialog:
	if Engine.is_editor_hint():
		return _editor_file_dialog
	return _file_dialog


func _command_button_list_pressed(command_script:Script) -> void:
	var command:Command = command_script.new()
	add_command(command)


func _timeline_displayer_item_mouse_selected(_position:Vector2, button_index:int) -> void:
	if button_index == MOUSE_BUTTON_RIGHT:
		var item = timeline_displayer.get_item_at_position(_position)
		var can_move_up:bool
		var can_move_down:bool
		if item.command:
			var c_pos:int = item.command.weak_owner.get_ref().get_command_position(item.command)
			var c_max_size:int = item.command.weak_owner.get_ref().collection.size()
			can_move_up = c_pos != 0
			can_move_down = c_pos < c_max_size - 1
		_item_popup.clear()
		_item_popup.add_item("Move up", _ItemPopup.MOVE_UP)
		_item_popup.set_item_disabled(0, !can_move_up)
		_item_popup.add_item("Move down", _ItemPopup.MOVE_DOWN)
		_item_popup.set_item_disabled(1, !can_move_down)
		_item_popup.add_separator()
		_item_popup.add_item("Duplicate", _ItemPopup.DUPLICATE)
		_item_popup.add_item("Remove", _ItemPopup.REMOVE)
		
		_item_popup.reset_size()
		_item_popup.position = DisplayServer.mouse_get_position()
		_item_popup.popup()


func _timeline_displayer_item_selected() -> void:
	if edit_callback.is_null():
		push_error("CollectionEditor: No edit callback was defined.")
		return
	
	var selected_command = timeline_displayer.get_selected().get_metadata(0)
	edit_callback.bind(selected_command).call_deferred()


func _timeline_displayer_get_drag_data(at_position: Vector2):
	var ref_block:TreeItem = timeline_displayer.get_item_at_position(at_position)

	if not ref_block:
		return null

	var drag_data = {&"type":"resource", &"resource":null, &"from":self}
	drag_data[&"resource"] = ref_block.get(&"command")
	
	if not drag_data[&"resource"]:
		return null
	
	if not drag_data[&"resource"].can_be_moved:
		return
	
	var drag_preview = Button.new()
	drag_preview.text = (drag_data.resource as Command).command_name
	set_drag_preview(drag_preview)
	
	return drag_data


func _timeline_displayer_can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var ref_block:TreeItem = timeline_displayer.get_item_at_position(at_position)
	var moved_command:Command = data.get(&"resource") as Command
	if not moved_command:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	if ref_block == timeline_displayer.root:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
		return true
	
	var ref_block_command:Command
	if ref_block:
		ref_block_command = ref_block.get(&"command")
	
		if ref_block_command.can_hold_commads:
			timeline_displayer.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
			return true
	
	if ref_block_command == moved_command:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	var command:Command = (data as Dictionary).get("resource") as Command
	if command:
		timeline_displayer.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		return true
	
	return false


func _timeline_displayer_drop_data(at_position: Vector2, data) -> void:
	var section:int = timeline_displayer.get_drop_section_at_position(at_position)
	var command:Command = data["resource"]
	var ref_item:TreeItem = timeline_displayer.get_item_at_position(at_position)
	var ref_item_collection:Collection
	if ref_item and ref_item != timeline_displayer.root:
		ref_item_collection = ref_item.command.weak_owner.get_ref()

	match section:
		_DropSection.NO_ITEM:
			move_command(command, -1, null, _current_timeline)

		_DropSection.ABOVE_ITEM:
			var new_index:int = ref_item.command.weak_owner.get_ref().get_command_position(ref_item.command)
			move_command(command, new_index, null, ref_item_collection)

		_DropSection.ON_ITEM:
			if ref_item == timeline_displayer.root:
				move_command(command, 0, null, _current_timeline)
				return
			
			move_command(command, -1, null, ref_item.command.commands)
			
			
		_DropSection.BELOW_ITEM:
			var new_index:int = ref_item.command.weak_owner.get_ref().get_command_position(ref_item.command) + 1
			move_command(command, new_index, null, ref_item_collection)


func _editor_file_dialog_file_selected(path:String) -> void:
	var timeline:CommandCollection
	var __file_dialog := _get_file_dialog()
		
	if __file_dialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		timeline = CommandCollection.new()
		timeline.resource_name = path.get_file()
		
		var err:int = ResourceSaver.save(timeline, path)
		if err != 0:
			push_error("Saving timeline failed with Error '%s'" % err)
			return
		timeline = load(path)
	
	timeline = load(path) as CommandCollection
	
	if not timeline:
		push_error("CollectionEditor: '%s' is not a valid Collection" % path)
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
	name = "CollectionEditor"
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
	_file_menu.add_item("New Collection...", ToolbarFileMenu.NEW_TIMELINE)
	_file_menu.add_item("Open Collection...", ToolbarFileMenu.OPEN_TIMELINE)
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
	timeline_displayer.name = "CollectionDisplayer"
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
	_help_panel_new_btn.text = "New Collection"
	_help_panel_new_btn.pressed.connect(_request_new_timeline)
	hb.add_child(_help_panel_new_btn)
	
	_help_panel_load_btn = Button.new()
	_help_panel_load_btn.text = "Load Collection"
	_help_panel_load_btn.pressed.connect(_request_load_timeline)
	hb.add_child(_help_panel_load_btn)
	
	show_help_panel()
	
	if Engine.is_editor_hint():
# https://github.com/godotengine/godot/issues/73525#issuecomment-1606067249
		_editor_file_dialog = (EditorFileDialog as Variant).new()
		_editor_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_editor_file_dialog)
	else:
		_file_dialog = FileDialog.new()
		_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_file_dialog)

	
