@tool
extends PanelContainer

class StateLayout:
	var folded_commands:Array[int] = []
	var last_selected_command_position:int = -1
	
	func to_dict() -> Dictionary:
		return {
			"folded_commands":folded_commands,
			"last_selected_command_position":last_selected_command_position,
		}
	
	func from_dict(val:Dictionary) -> void:
		folded_commands = val.get("folded_commands", [])
		last_selected_command_position = val.get("last_selected_command_position", -1)

const Blockflow = preload("res://addons/blockflow/blockflow.gd")
const CollectionDisplayer = preload("res://addons/blockflow/editor/displayer.gd")
const CommandList = preload("res://addons/blockflow/editor/command_list.gd")
const TemplateGenerator = preload("res://addons/blockflow/editor/template_generator.gd")

const Constants = preload("res://addons/blockflow/editor/constants.gd")

enum _ItemPopup {
	MOVE_UP, 
	MOVE_DOWN, 
	DUPLICATE,
	REMOVE,
	COPY,
	PASTE,
	CREATE_TEMPLATE,
	}

enum _DropSection {
	NO_ITEM = -100, 
	ABOVE_ITEM = -1,
	ON_ITEM,
	BELOW_ITEM,
	}

enum ToolbarFileMenu {
	NEW_COLLECTION,
	OPEN_COLLECTION,
	CLOSE_COLLECTION,
	RECENT_COLLECTION,
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

var collection_displayer:CollectionDisplayer
var command_list:CommandList
var title_label:Label
var template_generator:TemplateGenerator
var command_record:Blockflow.CommandRecord

var edit_callback:Callable
var toast_callback:Callable

var history:Dictionary = {}

var edited_object:Object

var state:StateLayout

# https://github.com/godotengine/godot/blob/4.0-stable/editor/editor_inspector.cpp#L3977
var command_clipboard:Blockflow.CommandClass:
	get:
		if Engine.has_meta("_blockflow_command_clipboard"):
			return Engine.get_meta("_blockflow_command_clipboard", null)
		return command_clipboard

var _current_collection:Blockflow.CollectionClass

var _item_popup:PopupMenu
var _moving_command:bool = false

var _help_panel:Container
var _help_panel_new_btn:Button
var _help_panel_load_btn:Button
var _help_panel_label:Label

var _toolbar:MenuBar
var _file_menu:PopupMenu
var _history_node:PopupMenu

var _editor_file_dialog:EditorFileDialog
var _file_dialog:FileDialog

func disable() -> void:
	propagate_notification(Constants.NOTIFICATION_EDITOR_DISABLED)

func enable() -> void:
	propagate_notification(Constants.NOTIFICATION_EDITOR_ENABLED)

func close() -> void:
	save_layout()
	collection_displayer.build_tree(null)
	_file_menu.set_item_disabled(
		_file_menu.get_item_index(ToolbarFileMenu.CLOSE_COLLECTION),
		true
	)
	_current_collection = null
	edited_object = null
	title_label.text = ""
	update_history()
	show_help_panel()
	disable()


func edit(object:Object) -> void:
	if object is Blockflow.CommandCollectionClass:
		edit_collection(object as Blockflow.CommandCollectionClass)


func edit_collection(collection:Blockflow.CollectionClass) -> void:
	if not collection:
		collection_displayer.build_tree(null)
		_file_menu.set_item_disabled(
			_file_menu.get_item_index(ToolbarFileMenu.CLOSE_COLLECTION),
			true
		)
		
		show_help_panel()
		disable()
		return
		
	var path_hint:String = ""
	if edited_object:
		if edited_object.changed.is_connected(_current_collection_modified):
			edited_object.changed.disconnect(_current_collection_modified)
		
		for command in edited_object._command_list:
			if command.collection_changed.is_connected(_current_collection_modified):
				command.collection_changed.disconnect(_current_collection_modified)
		
		save_layout()
		
	
	_current_collection = collection
	edited_object = collection
	
	if not _current_collection.changed.is_connected(_current_collection_modified):
		_current_collection.changed.connect(_current_collection_modified)
	
	for command in _current_collection._command_list:
		if not command.collection_changed.is_connected(_current_collection_modified):
			command.collection_changed.connect(_current_collection_modified)
		
	path_hint = _current_collection.resource_path
	restore_layout()
	hide_help_panel()
	enable()
	_file_menu.set_item_disabled(_file_menu.get_item_index(ToolbarFileMenu.CLOSE_COLLECTION), false)
	
	history[path_hint.get_file()] = path_hint
	update_history()
	
	title_label.text = path_hint
#	Blockflow.generate_tree(edited_object)
	collection_displayer.build_tree(_current_collection)


func add_command(command:Blockflow.CommandClass, at_position:int = -1, to_collection:Blockflow.CollectionClass = null) -> void:
	if not _current_collection: return
	if not command: return
	if not to_collection:
		to_collection = _current_collection
	
	
	var action_name:String = "Add command '%s'" % [command.command_name]
	collection_displayer.last_selected_command = command
	state.last_selected_command_position = at_position
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


func move_command(command:Blockflow.CommandClass, to_position:int, from_collection:Blockflow.CollectionClass=null, to_collection:Blockflow.CollectionClass=null) -> void:
	if not _current_collection: return
	if not command: return
	
	if not from_collection:
		from_collection = command.get_command_owner()
	if not to_collection:
		to_collection = command.get_command_owner()
	
	if not from_collection:
		# It comes from nowhere, maybe we're adding instead of moving?
		add_command(command, to_position, to_collection)
		return

	if to_collection == command:
		push_error("Can't move into self!")
		return

	var weak_owner = to_collection.weak_owner
	if weak_owner:
		weak_owner = weak_owner.get_ref()
	while weak_owner:
		if weak_owner is WeakRef:
			weak_owner = weak_owner.get_ref()
		if weak_owner == command:
			push_error("Found self in parents, can't move into self!")
			return
		weak_owner = weak_owner.weak_owner

	var from_position:int = from_collection.get_command_position(command)
	var action_name:String = "Move command '%s'" % [command.command_name]
	collection_displayer.last_selected_command = command
	if Engine.is_editor_hint():
		if from_collection == to_collection:
			editor_undoredo.create_action(action_name, 0, from_collection)
			editor_undoredo.add_do_method(from_collection, "move", command, to_position)
			editor_undoredo.add_undo_method(from_collection, "move", command, from_position)
			editor_undoredo.commit_action()
		else:
			action_name += " (collection change)"
			editor_undoredo.create_action(action_name, 0, Blockflow)
			editor_undoredo.add_do_method(Blockflow, "move_to_collection", command, to_collection, to_position)
			editor_undoredo.add_undo_method(Blockflow, "move_to_collection", command, from_collection, from_position)
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
		undo_redo.add_do_method(_current_collection.update)
		undo_redo.add_undo_method(_current_collection.update)
		
		undo_redo.commit_action()

func duplicate_command(command:Blockflow.CommandClass, to_index:int) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:Blockflow.CollectionClass
	if not command.weak_owner:
		push_error("!command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("!command_collection")
		return
	
	var action_name:String = "Duplicate command '%s'" % [command.command_name]
	var duplicated_command = command.get_duplicated()
	collection_displayer.last_selected_command = duplicated_command
	var idx = to_index if to_index > -1 else command_collection.size()
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(command_collection, "insert", duplicated_command, idx)
		editor_undoredo.add_undo_method(command_collection, "erase", duplicated_command)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(command_collection.insert.bind(duplicated_command, to_index))
		undo_redo.add_undo_method(command_collection.erase.bind(duplicated_command))
		
		undo_redo.commit_action()


func remove_command(command:Blockflow.CommandClass) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:Blockflow.CollectionClass
	if not command.weak_owner:
		push_error("not command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("not command_collection")
		return
	
	var action_name:String = "Remove command '%s'" % [command.command_name]
	
	if Engine.is_editor_hint():
		editor_undoredo.create_action(action_name)
		editor_undoredo.add_do_method(command_collection, "remove", command.index)
		editor_undoredo.add_undo_method(command_collection, "insert", command, command.index)
		editor_undoredo.commit_action()
	else:
		undo_redo.create_action(action_name)
		
		undo_redo.add_do_method(command_collection.remove.bind(command.index))
		undo_redo.add_undo_method(command_collection.insert.bind(command, command.index))
		
		undo_redo.commit_action()

func copy_command(command:Blockflow.CommandClass) -> void:
	command_clipboard = command
	Engine.set_meta("_blockflow_command_clipboard", command)

func show_help_panel():
	_help_panel.show()


func hide_help_panel():
	_help_panel.hide()

func update_history() -> void:
	_history_node.clear()
	if history.is_empty():
		_history_node.add_item("No recent collections...")
		_history_node.set_item_disabled(0, true)
		return
	
	var keys := history.keys()
	for i in keys.size():
		var history_key:String = keys[i]
		_history_node.add_item(history_key)
		_history_node.set_item_tooltip(i, history[history_key])
		
		if _current_collection and history[history_key] == _current_collection.resource_path:
			_history_node.set_item_text(i, history_key + " (Current)")
			_history_node.set_item_disabled(i, true)


func save_layout() -> void:
	if not _current_collection: return
	
	var layout:ConfigFile = ConfigFile.new()
	
	var data := Blockflow.generate_tree(_current_collection)
	
	for command in data.command_list:
		if command.editor_state.get("folded", false):
			state.folded_commands.append(command.position)
	
	layout.set_value(_current_collection.resource_path, "state", state.to_dict())
	
	var error:Error = layout.save(Constants.DEFAULT_LAYOUT_FILE)
	if error:
		push_error(error)


func restore_layout() -> void:
	if not _current_collection: return
	
	var layout:ConfigFile = ConfigFile.new()
	
	var error:Error = layout.load(Constants.DEFAULT_LAYOUT_FILE)
	state = StateLayout.new()
	
	if error == ERR_FILE_NOT_FOUND:
		return
	
	if error:
		push_error(error)
		return
	
	if not layout.has_section(_current_collection.resource_path):
		return
	
	state.from_dict(layout.get_value(_current_collection.resource_path, "state", {}))

	for pos in state.folded_commands:
		var command = _current_collection.get_command(pos)
		command.editor_state["folded"] = true
	
	if state.last_selected_command_position > -1:
		var command = _current_collection.get_command(state.last_selected_command_position)
		# FIXME: Selection should be by position, not by using the command directly
	

func _request_open() -> void:
	var __file_dialog := _get_file_dialog()
	__file_dialog.current_dir = ""
	__file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	__file_dialog.filters = ["*.tres, *.res ; Resource file"]
	__file_dialog.title = "Load Collection"
	__file_dialog.popup_centered_ratio(0.5)


func _request_new() -> void:
	var __file_dialog := _get_file_dialog()
	__file_dialog.current_dir = ""
	__file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	__file_dialog.filters = ["*.tres, *.res ; Resource file"]
	__file_dialog.title = "New CommandCollection"
	__file_dialog.popup_centered_ratio(0.5)


func _item_popup_id_pressed(id:int) -> void:
	var command:Blockflow.CommandClass = collection_displayer.get_selected().get_metadata(0)
	var command_idx:int = command.index
	match id:
		_ItemPopup.MOVE_UP:
			move_command(command, max(0, command_idx - 1))
			
		_ItemPopup.MOVE_DOWN:
			move_command(command, command_idx + 1)

		_ItemPopup.DUPLICATE:
			duplicate_command(command, command_idx + 1)
			
		_ItemPopup.REMOVE:
			remove_command(command)
		
		_ItemPopup.COPY:
			copy_command(command)
		
		_ItemPopup.PASTE:
			add_command(command_clipboard.get_duplicated(), command_idx + 1, command.get_command_owner())
		
		_ItemPopup.CREATE_TEMPLATE:
			template_generator.create_from(command)


func _get_file_dialog() -> ConfirmationDialog:
	if Engine.is_editor_hint():
		return _editor_file_dialog
	return _file_dialog


func _command_button_list_pressed(command:Blockflow.CommandClass) -> void:
	var command_idx:int = -1
	var tree_item:TreeItem = collection_displayer.get_selected()
	var new_command:Blockflow.CommandClass = command.get_duplicated()
	var in_collection:Blockflow.CollectionClass = _current_collection
	if tree_item:
		var selected:Blockflow.CommandClass = collection_displayer.get_selected().get_metadata(0) as Blockflow.CommandClass
		if selected:
			if selected.can_hold_commands:
				command_idx = -1
				in_collection = selected
			else:
				command_idx = selected.index + 1
				in_collection = selected.get_command_owner()
			
	collection_displayer.last_selected_command = new_command
	add_command(new_command, command_idx, in_collection)


func _collection_displayer_item_mouse_selected(_position:Vector2, button_index:int) -> void:
	if button_index == MOUSE_BUTTON_RIGHT:
		var item = collection_displayer.get_item_at_position(_position)
		var can_move_up:bool
		var can_move_down:bool
		if item.command:
			var c_pos:int = item.command.weak_owner.get_ref().get_command_position(item.command)
			var c_max_size:int = item.command.weak_owner.get_ref().collection.size()
			can_move_up = c_pos != 0
			can_move_down = c_pos < c_max_size - 1
		_item_popup.clear()
		
		_item_popup.add_item("Move up", _ItemPopup.MOVE_UP)
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.MOVE_UP), Constants.SHORTCUT_MOVE_UP)
		_item_popup.set_item_disabled(0, !can_move_up)
		_item_popup.add_item("Move down", _ItemPopup.MOVE_DOWN)
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.MOVE_DOWN), Constants.SHORTCUT_MOVE_DOWN)
		_item_popup.set_item_disabled(1, !can_move_down)
		_item_popup.add_separator()
		_item_popup.add_item("Duplicate", _ItemPopup.DUPLICATE)
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.DUPLICATE), Constants.SHORTCUT_DUPLICATE)
		_item_popup.add_item("Remove", _ItemPopup.REMOVE)
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.REMOVE), Constants.SHORTCUT_DELETE)
		
		_item_popup.add_separator()
		
		_item_popup.add_item("Copy", _ItemPopup.COPY)
		_item_popup.set_item_icon(_item_popup.get_item_index(_ItemPopup.COPY), get_theme_icon("ActionCopy", "EditorIcons"))
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.COPY), Constants.SHORTCUT_COPY)
		
		_item_popup.add_item("Paste", _ItemPopup.PASTE)
		_item_popup.set_item_icon(_item_popup.get_item_index(_ItemPopup.PASTE), get_theme_icon("ActionPaste", "EditorIcons"))
		_item_popup.set_item_disabled(_item_popup.get_item_index(_ItemPopup.PASTE), command_clipboard == null)
		_item_popup.set_item_shortcut(_item_popup.get_item_index(_ItemPopup.PASTE), Constants.SHORTCUT_PASTE)
		
		_item_popup.add_separator()
		
		_item_popup.add_item("Create Template...", _ItemPopup.CREATE_TEMPLATE)
		
		_item_popup.reset_size()
		_item_popup.position = DisplayServer.mouse_get_position()
		_item_popup.popup()


func _collection_displayer_item_selected() -> void:
	if edit_callback.is_null():
		push_error("CollectionEditor: No edit callback was defined.")
		return
	
	var selected_command = collection_displayer.get_selected().get_metadata(0)
	state.last_selected_command_position = selected_command.position
	edit_callback.bind(selected_command).call_deferred()


func _collection_displayer_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var block:CollectionDisplayer.CommandBlock = item as CollectionDisplayer.CommandBlock
	if not block: return
	
	var command:Blockflow.CommandClass = block.command
	if not command: return
	
	if id == CollectionDisplayer.CommandBlock.ButtonHint.CONTINUE_AT_END:
		if Engine.is_editor_hint():
			editor_undoredo.create_action("Set continue_at_end")
			editor_undoredo.add_do_property(command, "continue_at_end", not command.continue_at_end)
			editor_undoredo.add_undo_property(command, "continue_at_end", command.continue_at_end)
			editor_undoredo.commit_action()


func _collection_displayer_get_drag_data(at_position: Vector2):
	var ref_block:TreeItem = collection_displayer.get_item_at_position(at_position)

	if not ref_block:
		return null

	var drag_data = {&"type":"resource", &"resource":null, &"from":self}
	drag_data[&"resource"] = ref_block.get(&"command")
	
	if not drag_data[&"resource"]:
		return null
	
	if not drag_data[&"resource"].can_be_moved:
		return
	
	var drag_preview = Button.new()
	drag_preview.text = (drag_data.resource as Blockflow.CommandClass).command_name
	set_drag_preview(drag_preview)
	
	return drag_data


func _collection_displayer_can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var ref_block:TreeItem = collection_displayer.get_item_at_position(at_position)
	var moved_command:Blockflow.CommandClass = data.get(&"resource") as Blockflow.CommandClass
	if not moved_command:
		collection_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	if ref_block == collection_displayer.root:
		collection_displayer.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
		return true
	
	var ref_block_command:Blockflow.CommandClass
	if ref_block:
		ref_block_command = ref_block.get(&"command")
	
		if ref_block_command == moved_command:
			collection_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
			return false
		
		collection_displayer.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		
		if ref_block_command.can_hold_commands:
			if ref_block_command.can_hold(moved_command):
				collection_displayer.drop_mode_flags |= Tree.DROP_MODE_ON_ITEM
				return true
			else:
				collection_displayer.drop_mode_flags = Tree.DROP_MODE_DISABLED
				return false

		return true
	
	return true


func _collection_displayer_drop_data(at_position: Vector2, data) -> void:
	var section:int = collection_displayer.get_drop_section_at_position(at_position)
	var command:Blockflow.CommandClass = data["resource"]
	var ref_item:TreeItem = collection_displayer.get_item_at_position(at_position)
	var ref_item_collection:Blockflow.CollectionClass
	var ref_item_command:Blockflow.CommandClass
	if ref_item and ref_item != collection_displayer.root:
		ref_item_collection = ref_item.command.get_command_owner()
		ref_item_command = ref_item.command
	

	match section:
		_DropSection.NO_ITEM:
			move_command(command, -1, null, _current_collection)

		_DropSection.ABOVE_ITEM:
			var prev_c:Blockflow.CommandClass = ref_item_collection.get_command(max(0, ref_item.command.index - 1))
			if prev_c == command:
				# No need to move
				return
			var new_index:int = ref_item.command.index - int(ref_item.command.index >= command.index)
			if ref_item_collection != command.get_command_owner():
				new_index = ref_item.command.index
			
			move_command(command, new_index, null, ref_item_collection)

		_DropSection.ON_ITEM:
			if ref_item == collection_displayer.root:
				move_command(command, 0, null, _current_collection)
				return
			
			move_command(command, -1, null, ref_item.command)
			
			
		_DropSection.BELOW_ITEM:
			if ref_item_command.can_hold(command):
				move_command(command, 0, null, ref_item.command)
				return
			
			var next_c:Blockflow.CommandClass
			
			var new_index:int = ref_item.command.index + int(ref_item.command.index < command.index)
			
			if ref_item_collection != command.get_command_owner():
				new_index = ref_item.command.index + 1
			
			move_command(command, new_index, null, ref_item_collection)


func _editor_file_dialog_file_selected(path:String) -> void:
	var collection:Blockflow.CommandCollectionClass
	var __file_dialog := _get_file_dialog()
		
	if __file_dialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		collection = Blockflow.CommandCollectionClass.new()
		collection.resource_name = path.get_file()
		
		var err:int = ResourceSaver.save(collection, path)
		if err != 0:
			push_error("Saving CommandCollection failed with Error '%s'(%s)" % [err, error_string(err)])
			return
		collection = load(path)
	
	var resource:Resource = load(path)
	var condition:bool = resource is Blockflow.CommandCollectionClass
	if not resource or not condition:
		push_error("CollectionEditor: '%s' is not a valid Collection" % path)
		return
	
	edit_callback.bind(resource).call_deferred()


func _toolbar_file_menu_id_pressed(id:int) -> void:
	match id:
		ToolbarFileMenu.NEW_COLLECTION:
			_request_new()
		ToolbarFileMenu.OPEN_COLLECTION:
			_request_open()
		ToolbarFileMenu.CLOSE_COLLECTION:
			close()
			edit_callback.get_object().call("edit_node", null)


func _history_node_item_selected(index:int) -> void:
	var res:Resource = load(_history_node.get_item_tooltip(index))
	if not res: return
	edit(res)


func _current_collection_modified() -> void:
	var data := Blockflow.generate_tree(_current_collection)
	for command in data.command_list:
		if not command.collection_changed.is_connected(_current_collection_modified):
			command.collection_changed.connect(_current_collection_modified)
		
		command.editor_state = {
			"folded": false
		}
		if is_instance_valid(command.editor_block):
			command.editor_state["folded"] = command.editor_block.collapsed
	
	collection_displayer.build_tree(_current_collection)

func _shortcut_input(event: InputEvent) -> void:
	var focus_owner:Control = get_viewport().gui_get_focus_owner()
	if not is_instance_valid(focus_owner):
		return
	
	if not (collection_displayer.is_ancestor_of(focus_owner) or collection_displayer == focus_owner):
		return
	
	if not is_instance_valid(collection_displayer.get_selected()):
		return
	
	var command:Blockflow.CommandClass = collection_displayer.get_selected().get_metadata(0)
	if not command:
		return
	
	var command_idx:int = command.index
	
	if Constants.SHORTCUT_MOVE_UP.matches_event(event):
		move_command(command, max(0, command_idx - 1))
		accept_event()
		return

	if Constants.SHORTCUT_MOVE_DOWN.matches_event(event):
		move_command(command, command_idx + 1)
		accept_event()
		return

	if Constants.SHORTCUT_DUPLICATE.matches_event(event):
		duplicate_command(command, command_idx + 1)
		accept_event()
		return
	
	if Constants.SHORTCUT_DELETE.matches_event(event):
		remove_command(command)
		accept_event()
		return
	
	if Constants.SHORTCUT_COPY.matches_event(event):
		copy_command(command)
	
	if Constants.SHORTCUT_PASTE.matches_event(event):
		if not command_clipboard:
			return
		
		add_command(command_clipboard.get_duplicated(), command_idx + 1, command.get_command_owner())
	
	
	

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			_help_panel_load_btn.icon = get_theme_icon("Object", "EditorIcons")
			_help_panel_new_btn.icon = get_theme_icon("Load", "EditorIcons")
			title_label.add_theme_stylebox_override("normal", get_theme_stylebox("ContextualToolbar", "EditorStyles"))
		
		NOTIFICATION_POST_ENTER_TREE,NOTIFICATION_VISIBILITY_CHANGED:
			if not visible: return
			
			if edited_object:
				hide_help_panel()
				enable()
				return
			
			show_help_panel()
			disable()
		
		NOTIFICATION_PREDELETE:
			# Clean clipboard
			command_clipboard = null
			Engine.set_meta("_blockflow_command_clipboard", null)


func _init() -> void:
	name = "CollectionEditor"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme = load(Constants.DEFAULT_THEME_PATH) as Theme
	
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
	_file_menu.add_item("New Collection...", ToolbarFileMenu.NEW_COLLECTION)
	_file_menu.add_item("Open Collection...", ToolbarFileMenu.OPEN_COLLECTION)
	
	_history_node = PopupMenu.new()
	_history_node.name = "HistoryNode"
	_history_node.index_pressed.connect(_history_node_item_selected)
	_file_menu.add_child(_history_node)
	_file_menu.add_submenu_item("Open Recent", "HistoryNode", ToolbarFileMenu.RECENT_COLLECTION)
	update_history()
	
	_file_menu.add_separator()
	_file_menu.add_item("Close current collection", ToolbarFileMenu.CLOSE_COLLECTION)
	_file_menu.set_item_disabled(_file_menu.get_item_index(ToolbarFileMenu.CLOSE_COLLECTION), true)
	_toolbar.add_child(_file_menu)
	
	_toolbar.set_menu_title(0, "File")
	
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title_label)
	
	var hb:HBoxContainer = HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	
	var left_section := VSplitContainer.new()
	hb.add_child(left_section)
	
	command_list = CommandList.new()
	command_list.name = "CommandList"
	command_list.command_button_pressed_callback = _command_button_list_pressed
	left_section.add_child(command_list)
	
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.clip_contents = true
	hb.add_child(pc)
	
	collection_displayer = CollectionDisplayer.new()
	collection_displayer.name = "CollectionDisplayer"
	collection_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_displayer.item_mouse_selected.connect(_collection_displayer_item_mouse_selected)
	collection_displayer.item_selected.connect(_collection_displayer_item_selected)
	collection_displayer.button_clicked.connect(_collection_displayer_button_clicked)
	collection_displayer.set_drag_forwarding(_collection_displayer_get_drag_data, _collection_displayer_can_drop_data, _collection_displayer_drop_data)
	pc.add_child(collection_displayer)
	
	_help_panel = PanelContainer.new()
	_help_panel.name = "HelpPanel"
	_help_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_help_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.add_child(_help_panel)
	
	vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_help_panel.add_child(vb)
	
	_help_panel_label = Label.new()
	_help_panel_label.text = "You're not editing any collection."
	_help_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_help_panel_label)
	
	hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	
	_help_panel_new_btn = Button.new()
	_help_panel_new_btn.text = "New Collection"
	_help_panel_new_btn.pressed.connect(_request_new)
	hb.add_child(_help_panel_new_btn)
	
	_help_panel_load_btn = Button.new()
	_help_panel_load_btn.text = "Load Collection"
	_help_panel_load_btn.pressed.connect(_request_open)
	hb.add_child(_help_panel_load_btn)
	
	template_generator = TemplateGenerator.new()
	add_child(template_generator)
	
	if Engine.is_editor_hint():
# https://github.com/godotengine/godot/issues/73525#issuecomment-1606067249
		_editor_file_dialog = (EditorFileDialog as Variant).new()
		_editor_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_editor_file_dialog)
	else:
		_file_dialog = FileDialog.new()
		_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_file_dialog)
	
	command_record = Blockflow.CommandRecord.new()
	
	Engine.set_meta("Blockflow_main_editor", self)
