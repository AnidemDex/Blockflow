extends Control

const TimelineDisplayer = preload("res://addons/blockflow/editor/timeline_displayer.gd")
const CommandList = preload("res://addons/blockflow/command_list.gd")

enum _ItemPopup {
	MOVE_UP, 
	MOVE_DOWN, 
	REMOVE,
	}

enum _DropSection {
	NO_ITEM = -100, 
	ABOVE_ITEM = -1,
	IN_ITEM,
	UNDER_ITEM,
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

var timeline_displayer:TimelineDisplayer
var command_list:CommandList
var title_label:Label

var _current_timeline:Timeline

var _item_popup:PopupMenu
var _moving_command:bool = false

func edit_timeline(timeline:Timeline) -> void:
	var load_function:Callable = timeline_displayer.load_timeline
	
	if _current_timeline:
		if _current_timeline.changed.is_connected(load_function):
			_current_timeline.changed.disconnect(load_function)
	
	load_function.call(timeline)
	_current_timeline = timeline
	
	if _current_timeline:
		if not timeline.changed.is_connected(load_function):
			timeline.changed.connect(load_function.bind(timeline), CONNECT_DEFERRED)
	
	title_label.text = _current_timeline.resource_path
	timeline.emit_changed()


func add_command(command:Command, at_position:int = -1) -> void:
	if not _current_timeline: return
	if not command: return
	
	undo_redo.create_action("Add command '%s'" % [command.get_command_name()])
	
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
	
	undo_redo.create_action("Move command '%s'" % [command.get_command_name()])
	
	undo_redo.add_do_method(_current_timeline.move_command.bind(command, to_position))
	undo_redo.add_undo_method(_current_timeline.move_command.bind(command, old_position))
	
	undo_redo.commit_action()


func remove_command(command:Command) -> void:
	if not _current_timeline: return
	if not command: return
	
	var command_idx:int = _current_timeline.get_command_idx(command)
	
	undo_redo.create_action("Remove command '%s'" % [command.get_command_name()])
	
	undo_redo.add_do_method(_current_timeline.remove_command.bind(command_idx))
	undo_redo.add_undo_method(_current_timeline.insert_command.bind(command, command_idx))
	
	undo_redo.commit_action()


func _item_popup_id_pressed(id:int) -> void:
	var command:Command = timeline_displayer.get_selected().get_metadata(0)
	var command_idx:int = _current_timeline.get_command_idx(command)
	match id:
		_ItemPopup.MOVE_UP:
			move_command(command, max(0, command_idx - 1))
			
		_ItemPopup.MOVE_DOWN:
			move_command(command, command_idx + 1)
			
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
		_item_popup.add_item("Remove", _ItemPopup.REMOVE)
		
		_item_popup.reset_size()
		_item_popup.position = get_global_mouse_position()
		_item_popup.popup()


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


func _init() -> void:
#	if !Engine.is_editor_hint():
#		return
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stbx:StyleBoxFlat = StyleBoxFlat.new()
	stbx.bg_color = Color("353535")
	title_label.add_theme_stylebox_override("normal", stbx)
	add_child(title_label)
	
	_item_popup = PopupMenu.new()
	_item_popup.name = "ItemPopup"
	_item_popup.allow_search = false
	_item_popup.id_pressed.connect(_item_popup_id_pressed, CONNECT_DEFERRED)
	add_child(_item_popup)
	
	var hb:HBoxContainer = HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(hb)
	
	command_list = CommandList.new()
	command_list.name = "CommandList"
	command_list.command_button_list_pressed = _command_button_list_pressed
	hb.add_child(command_list)
	
	timeline_displayer = TimelineDisplayer.new()
	timeline_displayer.name = "TimelineDisplayer"
	timeline_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_displayer.item_mouse_selected.connect(_timeline_displayer_item_mouse_selected)
	timeline_displayer.set_drag_forwarding(_timeline_displayer_get_drag_data, _timeline_displayer_can_drop_data, _timeline_displayer_drop_data)
	hb.add_child(timeline_displayer)
