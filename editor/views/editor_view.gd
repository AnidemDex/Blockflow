@tool
extends PanelContainer

signal command_selected(resource)

const Constants = preload("res://addons/blockflow/editor/constants.gd")

const CommandList = preload("res://addons/blockflow/editor/command_list.gd")

const CollectionClass = preload("res://addons/blockflow/collection.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CCollectionClass = preload("res://addons/blockflow/command_collection.gd")
const CommandRecord = preload("res://addons/blockflow/core/command_record.gd")

const DisplayerFancy = preload("res://addons/blockflow/editor/displayer/fancy_displayer.gd")
const DisplayerSimple = preload("res://addons/blockflow/editor/displayer/simple_displayer.gd")
# TODO: Change FileMenu to MenuFile
enum ToolbarFileMenu {
	NEW,
	OPEN,
	CLOSE,
	RECENT,
}

enum ToolbarMenuEdit {
	UNDO,
	REDO
}

static var command_clipboard: Array[CommandClass]

var edited_object: Object:
	set = edit

var undo_redo: UndoRedo

var history: Dictionary
var last_selected_command: CommandClass
var command_record: CommandRecord

#region Editor Nodes
var displayer: Node

var toolbar: MenuBar
var menu_file: PopupMenu
var menu_recent: PopupMenu
var menu_edit: PopupMenu

var command_popup: PopupMenu

var command_list: CommandList

var file_dialog: Node

var section_left: PanelContainer
#endregion

var selected_commands: Array

#region EDITOR PRIVATE DATA
# Current edited timeline
var _current_timeline
# Current edited event
var _current_event
# Current edited collection
var _current_collection: CollectionClass
# Current edited command
var _current_command: CommandClass
#endregion


func _get_selected_commands() -> Array[CommandClass]:
	var commands: Array[CommandClass] = []
	commands.assign(selected_commands)
	if last_selected_command and not commands.has(last_selected_command):
		commands.append(last_selected_command)
	return commands


func edit(object: Object) -> void:
	if edited_object:
		if edited_object == object:
			return
		# Discard undoredo, always. We probably should save undoredo state somewhere
		undo_redo.free()
		edited_object = null
	
	edited_object = null
	
	if not undo_redo:
		undo_redo = UndoRedo.new()
		tree_exited.connect(undo_redo.free)
		undo_redo.version_changed.connect(_undo_redo_version_changed)
	_undo_redo_version_changed()
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
	if not _current_timeline:
		left_section_hide()
	
	propagate_call("set", ["editor", self])
	propagate_notification(Constants.NOTIFICATION_EDITOR_ENABLED)

func disable() -> void:
	propagate_notification(Constants.NOTIFICATION_EDITOR_DISABLED)

func close() -> void:
	assert("NOT_IMPLEMENTED")

func add_command(command_or_commands, at_position: int = -1, to_collection: CollectionClass = null) -> void:
	if not _current_collection: return
	if not command_or_commands: return
	if not to_collection:
		to_collection = _current_collection
	
	var commands: Array[CommandClass] = []
	if command_or_commands is Array:
		commands.assign(command_or_commands)
	else:
		commands.append(command_or_commands)
	
	if commands.is_empty(): return
	
	var action_name: String
	if commands.size() == 1:
		action_name = "Add command '%s'" % [commands[0].command_name]
	else:
		action_name = "Add %d commands" % commands.size()
	
	last_selected_command = commands.back()
	
	disable()
	undo_redo.create_action(action_name)
	
	# We need to insert them in order so they appear contiguous
	# If at_position is -1 (append), we just append them one by one
	# Just increment position for each insert to keep them in order and hope nothing explodes
	
	var current_pos = at_position
	
	for cmd in commands:
		if current_pos < 0:
			undo_redo.add_do_method(to_collection.add.bind(cmd))
		else:
			undo_redo.add_do_method(to_collection.insert.bind(cmd, current_pos))
			current_pos += 1
		
		undo_redo.add_undo_method(to_collection.erase.bind(cmd))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()

func move_command(command_or_commands, to_position: int, from_collection: CollectionClass = null, to_collection: CollectionClass = null) -> void:
	if not _current_collection: return
	if not command_or_commands: return
	
	var commands: Array[CommandClass] = []
	if command_or_commands is Array:
		commands.assign(command_or_commands)
	else:
		commands.append(command_or_commands)
	
	if commands.is_empty(): return
	# Here come dragons...
	# Validate all commands have same owner if from_collection is not specified
	# Theorically, we can support moving from different collections if we handle it carefully
	# But for now let's assume they might come from different places if we are dragging, you never know
	# If we are dragging from the tree, they likely share the owner or we can find it.
	
	# Single command case logic extended to array
	
	if not to_collection:
		# If no target collection, assume target is the owner of the first command
		# (Moving within same list logic usually)
		to_collection = commands[0].get_command_owner()
	
	if not to_collection:
		# If still no collection, we can't move
		return

	# Check for self-inclusion (moving a parent into a child)
	var weak_owner = to_collection.weak_owner
	if weak_owner:
		weak_owner = weak_owner.get_ref()
	while weak_owner:
		if weak_owner is WeakRef:
			weak_owner = weak_owner.get_ref()
		
		for cmd in commands:
			if weak_owner == cmd:
				push_error("Found self in parents, can't move into self!")
				return
		# Readable as a puzzle
		weak_owner = weak_owner.weak_owner

	var action_name: String
	if commands.size() == 1:
		action_name = "Move command '%s'" % [commands[0].command_name]
	else:
		action_name = "Move %d commands" % commands.size()
	
	disable()
	undo_redo.create_action(action_name)
	
	# We need to sort commands by index if they are in the same collection
	# to avoid index shifting issues when moving.
	# However, they might be in different collections.
	
	# Group by collection to handle removals
	var commands_by_collection = {}
	for cmd in commands:
		var owner_col = cmd.get_command_owner()
		if not owner_col: continue # Should not happen for existing commands
		if not commands_by_collection.has(owner_col):
			commands_by_collection[owner_col] = []
		commands_by_collection[owner_col].append(cmd)
	
	# For removal, we should process from highest index to lowest index 
	# to avoid shifting affecting subsequent removals in the same list
	# If we use 'undo' (insert at index), we need to know the ORIGINAL index.
	
	# Get original indices and pray yo don't mix position term with index term
	var command_info = [] # Stores {cmd, from_col, from_idx}
	
	for cmd in commands:
		var owner_col = cmd.get_command_owner()
		if not owner_col:
			# New command?
			command_info.append({
				"cmd": cmd,
				"from_col": null,
				"from_idx": - 1
			})
		else:
			command_info.append({
				"cmd": cmd,
				"from_col": owner_col,
				"from_idx": owner_col.get_command_position(cmd)
			})

	# If moving within the SAME collection, we need to be careful.
	# If we remove all then insert all, it works.
	
	# DO PHASE:
	# 1. Remove from old locations
	# 2. Insert into new location
	
	# UNDO PHASE:
	# 1. Remove from new location
	# 2. Insert into old locations (must be done in correct order to restore indices)
	
	# Sort command_info by from_idx descending for correct restoration if in same collection?
	# Actually, if we restore using 'insert' at original index, we should restore 
	# from lowest index to highest index? 
	# Example: List [A, B, C]. Remove A (0), B (1). List [C].
	# Restore A at 0 -> [A, C]. Restore B at 1 -> [A, B, C]. Correct.
	# So for UNDO (restoration), we want to insert in ascending order of original index.
	
	# Sort command_info for consistent handling
	# We can't easily sort if they are from different collections, but usually they are from one.
	# If multiple collections, order doesn't matter between collections.
	
	command_info.sort_custom(func(a, b):
		if a.from_col != b.from_col: return false # Arbitrary
		return a.from_idx < b.from_idx
	)
	
	# --- DO METHOD GENERATION ---
	
	# 1. Remove from source
	# If we use 'erase', it's safe.
	for info in command_info:
		if info.from_col:
			undo_redo.add_do_method(info.from_col.erase.bind(info.cmd))
	
	# 2. Insert into destination
	# We want to insert them at 'to_position'.
	# If to_position is -1, we append.
	# If we have multiple commands, we insert them sequentially.
	
	var current_insert_pos = to_position
	
	# If we are moving DOWN in the SAME collection, the indices will shift after removal.
	# But we are doing Remove-Then-Insert strategy.
	# So we need to calculate the *effective* insertion index if we were to do it atomically?
	# Or just trust that after removal, the indices are what they are.
	
	# Wait, if we use 'erase', the command is gone. 
	# Then we 'insert' into the collection which is now smaller.
	# If to_collection == from_collection:
	#   We need to adjust to_position?
	#   Example: [A, B, C, D, E]. Move [B, C] to after D (index 4).
	#   Remove B, C. List: [A, D, E].
	#   Target index was 4 (after D). But D is now at index 1.
	#   So we want to insert after D.
	#   This is tricky.
	
	# Simpler approach for same-collection move:
	# Use the `move` method of Collection if it's a single item.
	# But for multiple items, `move` isn't enough.
	
	# Let's stick to Remove-Then-Insert.
	# We need to know where to insert relative to the *remaining* items.
	
	# If to_position is based on the state *before* removal (which it usually is from drag data),
	# we need to adjust it by subtracting the count of items removed that were *before* to_position.
	
	if to_collection:
		var adjustment = 0
		if to_position != -1:
			for info in command_info:
				if info.from_col == to_collection and info.from_idx != -1 and info.from_idx < to_position:
					adjustment += 1
		
		var final_start_pos = to_position
		if final_start_pos != -1:
			final_start_pos -= adjustment
			# Clamp to 0
			final_start_pos = max(0, final_start_pos)
			# Clamp to size (after removal)
			# We need to know the size of to_collection AFTER removal.
			# But we haven't removed yet.
			# We can calculate it: current_size - count_of_removed_items_in_to_collection
			var removed_count = 0
			for info in command_info:
				if info.from_col == to_collection:
					removed_count += 1
			
			var max_pos = to_collection.size() - removed_count
			if final_start_pos > max_pos:
				final_start_pos = max_pos
		
		var loop_pos = final_start_pos
		for info in command_info:
			if loop_pos == -1:
				undo_redo.add_do_method(to_collection.add.bind(info.cmd))
			else:
				undo_redo.add_do_method(to_collection.insert.bind(info.cmd, loop_pos))
				loop_pos += 1

	# --- UNDO METHOD GENERATION ---
	
	# 1. Remove from destination
	for info in command_info:
		if to_collection:
			undo_redo.add_undo_method(to_collection.erase.bind(info.cmd))
	
	# 2. Insert back to source
	# We must do this in the order that preserves indices.
	# Since we sorted command_info by index ascending, if we insert in that order:
	# [A, B, C]. Remove A, B. -> [C].
	# Restore A (0) -> [A, C].
	# Restore B (1) -> [A, B, C].
	
	for info in command_info:
		if info.from_col:
			undo_redo.add_undo_method(info.from_col.insert.bind(info.cmd, info.from_idx))

	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	# Hello, future me. If you are reading this it implies that you f-c'd up, somewhere. 
	#Good luck solving this puzzle.
	undo_redo.commit_action()
	enable()

func duplicate_command(command_or_commands, to_index: int) -> void:
	if not _current_collection: return
	if not command_or_commands: return
	
	var commands: Array[CommandClass] = []
	if command_or_commands is Array:
		commands.assign(command_or_commands)
	else:
		commands.append(command_or_commands)
	
	if commands.is_empty(): return
	
	var target_collection = commands[0].get_command_owner()
	if not target_collection: return
	
	var action_name: String
	if commands.size() == 1:
		action_name = "Duplicate command '%s'" % [commands[0].command_name]
	else:
		action_name = "Duplicate %d commands" % commands.size()
	
	disable()
	undo_redo.create_action(action_name)
	
	var insert_pos = to_index
	if insert_pos == -1:
		# Find the max index in the selection to insert after it
		var max_idx = -1
		for cmd in commands:
			if cmd.get_command_owner() == target_collection:
				var idx = target_collection.get_command_position(cmd)
				if idx > max_idx: max_idx = idx
		if max_idx != -1:
			insert_pos = max_idx + 1
		else:
			insert_pos = target_collection.size()
	
	var new_commands = []
	for cmd in commands:
		var dup = cmd.get_duplicated()
		new_commands.append(dup)
	
	# Select the new commands
	selected_commands.clear()
	selected_commands.append_array(new_commands)
	last_selected_command = new_commands.back()
	
	var current_pos = insert_pos
	for cmd in new_commands:
		undo_redo.add_do_method(target_collection.insert.bind(cmd, current_pos))
		undo_redo.add_undo_method(target_collection.erase.bind(cmd))
		current_pos += 1
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()

func remove_command(command_or_commands) -> void:
	if not _current_collection: return
	if not command_or_commands: return
	
	var commands: Array[CommandClass] = []
	if command_or_commands is Array:
		commands.assign(command_or_commands)
	else:
		commands.append(command_or_commands)
	
	if commands.is_empty(): return
	
	var action_name: String
	if commands.size() == 1:
		action_name = "Remove command '%s'" % [commands[0].command_name]
	else:
		action_name = "Remove %d commands" % commands.size()
	
	disable()
	undo_redo.create_action(action_name)
	
	# Gather info for undo
	var command_info = []
	for cmd in commands:
		var owner_col = cmd.get_command_owner()
		if owner_col:
			command_info.append({
				"cmd": cmd,
				"col": owner_col,
				"idx": owner_col.get_command_position(cmd)
			})
	
	# Sort by index ascending for correct restoration
	command_info.sort_custom(func(a, b): return a.idx < b.idx)
	
	# Do: Remove
	for info in command_info:
		undo_redo.add_do_method(info.col.erase.bind(info.cmd))
	
	# Undo: Insert back
	for info in command_info:
		undo_redo.add_undo_method(info.col.insert.bind(info.cmd, info.idx))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.add_do_method(grab_focus.call_deferred)
	undo_redo.add_undo_method(grab_focus.call_deferred)
	
	undo_redo.commit_action()
	enable()


func copy_command(command_or_commands) -> void:
	if command_or_commands is Array:
		command_clipboard.assign(command_or_commands)
	else:
		command_clipboard = [command_or_commands]


func toolbar_update_menu_recent() -> void:
	menu_recent.clear()
	if history.is_empty():
		menu_recent.add_item("No recent resources...")
		menu_recent.set_item_disabled(0, true)
		return
	
	var keys := history.keys()
	for i in keys.size():
		var history_key: String = keys[i]
		menu_recent.add_item(history_key)
		menu_recent.set_item_tooltip(i, history[history_key])
		
		if edited_object and history[history_key] == edited_object.resource_path:
			menu_recent.set_item_text(i, history_key + " (Current)")
			menu_recent.set_item_disabled(i, true)

func left_section_hide() -> void:
	section_left.visible = false

func left_section_show() -> void:
	section_left.visible = true


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
	var object: CCollectionClass = edited_object as CCollectionClass
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
	var object: CommandClass = edited_object as CommandClass
	displayer.display(object)


func _edit_collection() -> void:
	var object: CollectionClass = edited_object as CollectionClass
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
func _edited_object_changed(object: Object) -> void:
	if object == _current_collection:
		displayer.display(object)


func _command_popup_id_pressed(id: int) -> void:
	var commands: Array = _get_selected_commands()
		
	if commands.is_empty(): return
	
	# For single-command specific logic (like move up/down one step), 
	# we might want to iterate or handle differently.
	# But move_command now handles arrays.
	
	match id:
		Constants.ItemPopup.MOVE_UP:
			var min_idx = 9999999
			for cmd in commands:
				if cmd.index < min_idx: min_idx = cmd.index
			move_command(commands, max(0, min_idx - 1))
			
		Constants.ItemPopup.MOVE_DOWN:
			var max_idx = -1
			var collection_size = 0
			if not commands.is_empty():
				var cmd_owner = commands[0].get_command_owner()
				if cmd_owner: collection_size = cmd_owner.size()
				
			for cmd in commands:
				if cmd.index > max_idx: max_idx = cmd.index
			
			# If max_idx is already at the bottom, don't move
			if max_idx < collection_size - 1:
				move_command(commands, max_idx + 2)

		Constants.ItemPopup.DUPLICATE:
			duplicate_command(commands, -1)
			
		Constants.ItemPopup.REMOVE:
			remove_command(commands)
		
		Constants.ItemPopup.COPY:
			copy_command(commands)
		
		Constants.ItemPopup.PASTE:
			# Paste inserts clipboard content.
			# If we have a selection, we paste after it.
			# If multiple selected, paste after the last one
			var target_cmd = commands.back()
			var target_idx = target_cmd.index + 1
			var target_col = target_cmd.get_command_owner()
			
			var to_paste = []
			for cmd in command_clipboard:
				to_paste.append(cmd.get_duplicated())
				
			add_command(to_paste, target_idx, target_col)


func _toolbar_menu_file_id_pressed(id: int) -> void:
	match id:
		ToolbarFileMenu.NEW:
			request_new_command_collection()
		ToolbarFileMenu.OPEN:
			request_open_command_collection()
		ToolbarFileMenu.CLOSE:
			close()


func _toolbar_menu_recent_item_selected(index: int) -> void:
	pass


func _toolbar_menu_edit_id_pressed(id: int) -> void:
	match id:
		ToolbarMenuEdit.UNDO:
			undo_redo.undo()
		ToolbarMenuEdit.REDO:
			undo_redo.redo()


func _command_list_button_pressed(command: CommandClass) -> void:
	if not edited_object:
		return
	
	var command_idx: int = -1
	var new_command: CommandClass = command.get_duplicated()
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


func _displayer_command_selected(command: CommandClass) -> void:
	if Input.is_physical_key_pressed(KEY_CTRL):
		if last_selected_command:
			if is_instance_valid(last_selected_command.editor_block):
				last_selected_command.editor_block.keep_selected = true
			if not selected_commands.has(last_selected_command):
				selected_commands.append(last_selected_command)
	else:
		for selected_command in selected_commands:
			if is_instance_valid(selected_command.editor_block):
				selected_command.editor_block.keep_selected = false
		selected_commands.clear()
	
	_current_command = command
	last_selected_command = command
	command_selected.emit(last_selected_command)

func _displayer_display_finished() -> void:
	# Ensure all new blocks have the editor reference
	displayer.propagate_call("set", ["editor", self])
	
	if last_selected_command:
		if is_instance_valid(last_selected_command.editor_block):
			if not last_selected_command.editor_block.is_queued_for_deletion():
				last_selected_command.editor_block.select_no_signal()
	
	for cmd in selected_commands:
		if is_instance_valid(cmd.editor_block) and not cmd.editor_block.is_queued_for_deletion():
			cmd.editor_block.keep_selected = true


func _displayer_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var moved_command: CommandClass = data.get(&"resource", null) as CommandClass
	if not moved_command:
		return false
	
	return true


func _displayer_drop_data(at_position: Vector2, data: Variant) -> void:
	var drag_commands = data.get(&"commands", [])
	if drag_commands.is_empty():
		var single = data.get(&"resource", null)
		if single:
			drag_commands.append(single)
			
	if drag_commands.is_empty():
		return
	
	move_command(drag_commands, -1, null, _current_collection)


func _file_dialog_file_selected(path: String) -> void:
	var collection: CCollectionClass
		
	if file_dialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		collection = CCollectionClass.new()
		collection.resource_name = path.get_file()
		
		var err: int = ResourceSaver.save(collection, path)
		if err != 0:
			push_error("Saving CommandCollection failed with Error '%s'(%s)" % [err, error_string(err)])
			return
		collection = load(path)
	
	var resource: Resource = load(path)
	var condition: bool = resource is CollectionClass
	if not resource or not condition:
		push_error("CollectionEditor: '%s' is not a valid Collection" % path)
		return
	
	edit(resource)


func _undo_redo_version_changed() -> void:
	menu_edit.set_item_disabled(ToolbarMenuEdit.UNDO, !undo_redo.has_undo())
	menu_edit.set_item_disabled(ToolbarMenuEdit.REDO, !undo_redo.has_redo())

func _shortcut_input(event: InputEvent) -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	
	if Constants.SHORTCUT_UNDO.matches_event(event) and event.is_released():
		undo_redo.undo()
		accept_event()
	
	if Constants.SHORTCUT_REDO.matches_event(event) and event.is_released():
		undo_redo.redo()
		accept_event()
	
	if not is_instance_valid(focus_owner):
		return
	
	if not (displayer.is_ancestor_of(focus_owner) or displayer == focus_owner):
		return
	
	if not is_instance_valid(displayer.selected_item):
		return
	
	var commands: Array = _get_selected_commands()
		
	if commands.is_empty():
		return
	
	# Use the first command for context if needed (e.g. paste location)
	var primary_command = commands[0]
	
	if Constants.SHORTCUT_MOVE_UP.matches_event(event) and event.is_released():
		var min_idx = 9999999
		for cmd in commands:
			if cmd.index < min_idx: min_idx = cmd.index
		move_command(commands, max(0, min_idx - 1))
		accept_event()
		return

	if Constants.SHORTCUT_MOVE_DOWN.matches_event(event) and event.is_released():
		var max_idx = -1
		var collection_size = 0
		if not commands.is_empty():
			var cmd_owner = commands[0].get_command_owner()
			if cmd_owner: collection_size = cmd_owner.size()

		for cmd in commands:
			if cmd.index > max_idx: max_idx = cmd.index
		
		if max_idx < collection_size - 1:
			move_command(commands, max_idx + 2)
		accept_event()
		return

	if Constants.SHORTCUT_DUPLICATE.matches_event(event) and event.is_released():
		duplicate_command(commands, -1)
		accept_event()
		return
	
	if Constants.SHORTCUT_DELETE.matches_event(event) and event.is_released():
		remove_command(commands)
		accept_event()
		return
	
	if Constants.SHORTCUT_COPY.matches_event(event) and event.is_released():
		copy_command(commands)
	
	if Constants.SHORTCUT_PASTE.matches_event(event) and event.is_released():
		if command_clipboard.is_empty():
			return
		
		var target_cmd = primary_command
		var target_idx = target_cmd.index + 1
		var target_col = target_cmd.get_command_owner()
		
		var to_paste = []
		for cmd in command_clipboard:
			to_paste.append(cmd.get_duplicated())
			
		add_command(to_paste, target_idx, target_col)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			disable()
			left_section_hide()
			toolbar_update_menu_recent()
		
		Constants.NOTIFICATION_EDITOR_ENABLED:
			if not edited_object:
				push_warning("Why is the editor enabled when there is no edited object?")
				return
			
			toolbar.set_menu_hidden(1, false)
			toolbar.set_menu_disabled(1, false)
			# Force redraw, because somehow it doesn't show the button after setting it 'hidden'
			# TODO: Sidequest - Isolate, replicate and report to godotengine/godot
			toolbar.queue_redraw()
			
		
		Constants.NOTIFICATION_EDITOR_DISABLED:
			if not edited_object:
				toolbar.set_menu_hidden(1, true)
				toolbar.queue_redraw()
				return
			
			# Don't allow edits while performing blocking operations.
			toolbar.set_menu_disabled(1, true)
			toolbar.queue_redraw()


func _init() -> void:
	name = "BlockflowEditor"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme = load(Constants.DEFAULT_THEME_PATH) as Theme
	theme_type_variation = "BlockEditor"
	
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
	
	menu_edit = PopupMenu.new()
	menu_edit.allow_search = false
	menu_edit.id_pressed.connect(_toolbar_menu_edit_id_pressed)
	menu_edit.add_item("Undo", ToolbarMenuEdit.UNDO)
	menu_edit.add_item("Redo", ToolbarMenuEdit.REDO)
	menu_edit.set_item_disabled(ToolbarMenuEdit.UNDO, true)
	menu_edit.set_item_disabled(ToolbarMenuEdit.REDO, true)
	toolbar.add_child(menu_edit)
	
	toolbar.set_menu_title(1, &"Edit")
	toolbar.set_menu_hidden(1, true)
	
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	
	var split_left := SplitContainer.new()
	split_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(split_left)
	
	section_left = PanelContainer.new()
	#section_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#section_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#section_left.size_flags_stretch_ratio = 0.15
	var split_center := SplitContainer.new()
	#split_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#split_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_left.add_child(section_left)
	split_left.add_child(split_center)
	
	var section_center := PanelContainer.new()
	section_center.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
	
	displayer = DisplayerFancy.new()
	displayer.command_selected.connect(_displayer_command_selected)
	displayer.display_finished.connect(_displayer_display_finished)
	displayer.set_drag_forwarding(Callable(), _displayer_can_drop_data, _displayer_drop_data)
	displayer.focus_mode = Control.FOCUS_ALL
	displayer.mouse_filter = Control.MOUSE_FILTER_STOP
	displayer.shortcut_context = self
	section_center.add_child(displayer)
	
	file_dialog = FileDialog.new()
	file_dialog.file_selected.connect(_file_dialog_file_selected)
	add_child(file_dialog)
