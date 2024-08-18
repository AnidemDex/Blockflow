@tool
extends PanelContainer

const Constants = preload("res://addons/blockflow/editor/constants.gd")

const CommandList = preload("res://addons/blockflow/editor/command_list.gd")

const CollectionClass = preload("res://addons/blockflow/collection.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CCollectionClass = preload("res://addons/blockflow/command_collection.gd")
const CommandRecord = preload("res://addons/blockflow/core/command_record.gd")

const DisplayerFancy = preload("res://addons/blockflow/editor/displayer/fancy_displayer.gd")
const DisplayerSimple = preload("res://addons/blockflow/editor/displayer/simple_displayer.gd")

enum ToolbarFileMenu {
	NEW,
	OPEN,
	CLOSE,
	RECENT,
}

static var editors := {}
static var command_clipboard:CommandClass

var edited_object:Object:
	set=edit

var undo_redo:UndoRedo
var history:Dictionary
var last_selected_command:CommandClass
var command_record:CommandRecord

#region Editor Nodes
var displayer:Node

var toolbar:MenuBar
var menu_file:PopupMenu
var menu_recent:PopupMenu

var command_popup:PopupMenu

var command_list:CommandList

var file_dialog:Node
#endregion

var selected_commands:Array

#region EDITOR PRIVATE DATA
# Current edited timeline
var _current_timeline
# Current edited event
var _current_event
# Current edited collection
var _current_collection:CollectionClass
# Current edited command
var _current_command:CommandClass
#endregion


func edit(object:Object) -> void:
	edited_object = null
	#if object is TimelineClass:
		#left_section_show()
		#_edit_timeline()
	
	if object is CommandClass:
		edited_object = object
		_edit_command()
		return
	
	if object is CCollectionClass:
		edited_object = object
		_edit_command_collection()
		return
	
	if object is CollectionClass:
		edited_object = object
		_edit_collection()
		return

func enable() -> void:
	propagate_call("set", ["editor", self])
	propagate_notification(Constants.NOTIFICATION_EDITOR_ENABLED)

func disable() -> void:
	propagate_notification(Constants.NOTIFICATION_EDITOR_DISABLED)

func close() -> void:
	pass

func add_command(command:CommandClass, at_position:int = -1, to_collection:CollectionClass = null) -> void:
	if not _current_collection: return
	if not command: return
	if not to_collection:
		to_collection = _current_collection
	
	var action_name:String = "Add command '%s'" % [command.command_name]
	last_selected_command = command
	
	disable()
	undo_redo.create_action(action_name)
		
	if at_position < 0:
		undo_redo.add_do_method(to_collection.add.bind(command))
	else:
		undo_redo.add_do_method(to_collection.insert.bind(command, at_position))
	
	undo_redo.add_undo_method(to_collection.erase.bind(command))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()


func move_command(command:CommandClass, to_position:int, from_collection:CollectionClass=null, to_collection:CollectionClass=null) -> void:
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
	
	disable()
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
	enable()

func duplicate_command(command:CommandClass, to_index:int) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:CollectionClass
	if not command.weak_owner:
		push_error("!command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("!command_collection")
		return
	
	var action_name:String = "Duplicate command '%s'" % [command.command_name]
	var duplicated_command = command.get_duplicated()
	last_selected_command = duplicated_command
	var idx = to_index if to_index > -1 else command_collection.size()
	
	disable()
	undo_redo.create_action(action_name)
		
	undo_redo.add_do_method(command_collection.insert.bind(duplicated_command, to_index))
	undo_redo.add_undo_method(command_collection.erase.bind(duplicated_command))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()


func remove_command(command:CommandClass) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:CollectionClass
	if not command.weak_owner:
		push_error("not command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("not command_collection")
		return
	
	var action_name:String = "Remove command '%s'" % [command.command_name]
	
	disable()
	undo_redo.create_action(action_name)
		
	undo_redo.add_do_method(command_collection.remove.bind(command.index))
	undo_redo.add_undo_method(command_collection.insert.bind(command, command.index))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()


func copy_command(command:CommandClass) -> void:
	command_clipboard = command


func toolbar_update_menu_recent() -> void:
	menu_recent.clear()
	if history.is_empty():
		menu_recent.add_item("No recent resources...")
		menu_recent.set_item_disabled(0, true)
		return
	
	var keys := history.keys()
	for i in keys.size():
		var history_key:String = keys[i]
		menu_recent.add_item(history_key)
		menu_recent.set_item_tooltip(i, history[history_key])
		
		if edited_object and history[history_key] == edited_object.resource_path:
			menu_recent.set_item_text(i, history_key + " (Current)")
			menu_recent.set_item_disabled(i, true)

func left_section_hide() -> void:
	pass

func left_section_show() -> void:
	pass


func request_new_command_collection() -> void:
	file_dialog.current_dir = ""
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.filters = ["*.tres, *.res ; Resource file"]
	file_dialog.title = "New CommandCollection"
	file_dialog.popup_centered_ratio(0.5)


func request_open_command_collection() -> void:
	file_dialog.current_dir = ""
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.tres, *.res ; Resource file"]
	file_dialog.title = "Load Collection"
	file_dialog.popup_centered_ratio(0.5)

func _edit_timeline() -> void:
	#event_displayer.display(object.events)
	#displayer.display(object)
	pass


func _edit_command_collection() -> void:
	var object:CCollectionClass = edited_object as CCollectionClass
	displayer.display(object)
	
	if not object:
		_disconnect_current_collection_signals()
		disable()
		return
	
	if object != _current_collection:
		_disconnect_current_collection_signals()
		_current_collection = object
		_connect_current_collection_signals()
	
	enable()


func _edit_command() -> void:
	var object:CommandClass = edited_object as CommandClass
	displayer.display(object)


func _edit_collection() -> void:
	var object:CollectionClass = edited_object as CollectionClass
	displayer.display(object)


func _connect_current_collection_signals() -> void:
	if not _current_collection:
		return
	
	if _current_collection.collection_changed.is_connected(_edited_object_changed):
		return
	
	_current_collection.collection_changed.connect(_edited_object_changed.bind(_current_collection))

func _disconnect_current_collection_signals() -> void:
	if not _current_collection:
		return
	
	if not _current_collection.collection_changed.is_connected(_edited_object_changed):
		return
	
	_current_collection.collection_changed.disconnect(_edited_object_changed)


# Resource.changed signal was emited
func _edited_object_changed(object:Object) -> void:
	if object == _current_collection:
		displayer.display(object)


func _command_popup_id_pressed(id:int) -> void:
	var command:CommandClass = _current_command
	var command_idx:int = command.index
	match id:
		Constants.ItemPopup.MOVE_UP:
			move_command(command, max(0, command_idx - 1))
			
		Constants.ItemPopup.MOVE_DOWN:
			move_command(command, command_idx + 1)

		Constants.ItemPopup.DUPLICATE:
			duplicate_command(command, command_idx + 1)
			
		Constants.ItemPopup.REMOVE:
			remove_command(command)
		
		Constants.ItemPopup.COPY:
			copy_command(command)
		
		Constants.ItemPopup.PASTE:
			add_command(command_clipboard.get_duplicated(), command_idx + 1, command.get_command_owner())


func _toolbar_menu_file_id_pressed(id:int) -> void:
	match id:
		ToolbarFileMenu.NEW:
			request_new_command_collection()
		ToolbarFileMenu.OPEN:
			request_open_command_collection()
		ToolbarFileMenu.CLOSE:
			close()


func _toolbar_menu_recent_item_selected(index:int) -> void:
	pass


func _command_list_button_pressed(command:CommandClass) -> void:
	if not edited_object:
		return
	
	var command_idx:int = -1
	var new_command:CommandClass = command.get_duplicated()
	var in_collection = _current_collection
	if last_selected_command:
		if last_selected_command.can_hold_commands:
			command_idx = -1
			in_collection = last_selected_command
		else:
			command_idx = last_selected_command.index + 1
			in_collection = last_selected_command.get_command_owner()
			
	last_selected_command = new_command
	add_command(new_command, command_idx, in_collection)


func _displayer_command_selected(command:CommandClass) -> void:
	if Input.is_physical_key_pressed(KEY_CTRL):
		if last_selected_command:
			last_selected_command.editor_block.keep_selected = true
			selected_commands.append(last_selected_command)
	else:
		for selected_command in selected_commands:
			selected_command.editor_block.keep_selected = false
		selected_commands.clear()
	
	_current_command = command
	last_selected_command = command

func _displayer_display_finished() -> void:
	if not last_selected_command:
		return
	
	if is_instance_valid(last_selected_command.editor_block):
		last_selected_command.editor_block.select()


func _displayer_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var moved_command:CommandClass = data.get(&"resource", null) as CommandClass
	if not moved_command:
		return false
	
	return true


func _displayer_drop_data(at_position: Vector2, data: Variant) -> void:
	var drag_command:CommandClass = data.get(&"resource", null)
	if not drag_command:
		return
	
	move_command(drag_command, -1, null, _current_collection)


func _file_dialog_file_selected(path:String) -> void:
	var collection:CCollectionClass
		
	if file_dialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		collection = CCollectionClass.new()
		collection.resource_name = path.get_file()
		
		var err:int = ResourceSaver.save(collection, path)
		if err != 0:
			push_error("Saving CommandCollection failed with Error '%s'(%s)" % [err, error_string(err)])
			return
		collection = load(path)
	
	var resource:Resource = load(path)
	var condition:bool = resource is CollectionClass
	if not resource or not condition:
		push_error("CollectionEditor: '%s' is not a valid Collection" % path)
		return
	
	edit(resource)


func _shortcut_input(event: InputEvent) -> void:
	var focus_owner:Control = get_viewport().gui_get_focus_owner()
	if not is_instance_valid(focus_owner):
		return
	
	if not (displayer.is_ancestor_of(focus_owner) or displayer == focus_owner):
		return
	
	if not is_instance_valid(displayer.selected_item):
		return
	
	var command:CommandClass = displayer.selected_item.command
	if not command:
		return
	
	var command_idx:int = command.index
	
	if Constants.SHORTCUT_MOVE_UP.matches_event(event) and event.is_released():
		move_command(command, max(0, command_idx - 1))
		accept_event()
		return

	if Constants.SHORTCUT_MOVE_DOWN.matches_event(event) and event.is_released():
		move_command(command, command_idx + 1)
		accept_event()
		return

	if Constants.SHORTCUT_DUPLICATE.matches_event(event) and event.is_released():
		duplicate_command(command, command_idx + 1)
		accept_event()
		return
	
	if Constants.SHORTCUT_DELETE.matches_event(event) and event.is_released():
		remove_command(command)
		accept_event()
		return
	
	if Constants.SHORTCUT_COPY.matches_event(event) and event.is_released():
		copy_command(command)
	
	if Constants.SHORTCUT_PASTE.matches_event(event) and event.is_released():
		if not command_clipboard:
			return
		
		add_command(command_clipboard.get_duplicated(), command_idx + 1, command.get_command_owner())


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if not edited_object:
				disable()


func _init() -> void:
	name = "BlockflowEditor"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme = load(Constants.DEFAULT_THEME_PATH) as Theme
	
	command_popup = PopupMenu.new()
	command_popup.name = "ItemPopup"
	command_popup.allow_search = false
	command_popup.exclusive = false
	command_popup.id_pressed.connect(_command_popup_id_pressed, CONNECT_DEFERRED)
	add_child(command_popup)
	
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vb)
	
	toolbar = MenuBar.new()
	toolbar.flat = true
	vb.add_child(toolbar)
	
	menu_file = PopupMenu.new()
	menu_file.allow_search = false
	menu_file.id_pressed.connect(_toolbar_menu_file_id_pressed)
	menu_file.add_item("New...", ToolbarFileMenu.NEW)
	menu_file.add_item("Open...", ToolbarFileMenu.OPEN)
	
	menu_recent = PopupMenu.new()
	menu_recent.name = "HistoryNode"
	menu_recent.index_pressed.connect(_toolbar_menu_recent_item_selected)
	menu_file.add_child(menu_recent)
	menu_file.add_submenu_item("Open Recent", "HistoryNode", ToolbarFileMenu.RECENT)
	toolbar_update_menu_recent()
	
	menu_file.add_separator()
	menu_file.add_item("Close current collection", ToolbarFileMenu.CLOSE)
	menu_file.set_item_disabled(menu_file.get_item_index(ToolbarFileMenu.CLOSE), true)
	toolbar.add_child(menu_file)
	
	toolbar.set_menu_title(0, "File")
	
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	
	var split_left := SplitContainer.new()
	split_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(split_left)
	
	var section_left := PanelContainer.new()
	section_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_left.size_flags_stretch_ratio = 0.15
	var split_center := SplitContainer.new()
	split_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_left.add_child(section_left)
	split_left.add_child(split_center)
	
	var section_center := PanelContainer.new()
	section_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var section_right := PanelContainer.new()
	split_center.add_child(section_center)
	split_center.add_child(section_right)
	
	command_list = CommandList.new()
	command_list.name = "CommandList"
	command_list.command_button_pressed_callback = _command_list_button_pressed
	section_right.add_child(command_list)
	
	command_record = CommandRecord.new().get_record()
	
	editors[&"unknow_editors"] = editors.get(&"unknow_editors", [])
	editors[&"unknow_editors"].append(self)
	
	displayer = DisplayerFancy.new()
	displayer.command_selected.connect(_displayer_command_selected)
	displayer.display_finished.connect(_displayer_display_finished)
	displayer.set_drag_forwarding(Callable(), _displayer_can_drop_data, _displayer_drop_data)
	section_center.add_child(displayer)
	
	file_dialog = FileDialog.new()
	file_dialog.file_selected.connect(_file_dialog_file_selected)
	add_child(file_dialog)
