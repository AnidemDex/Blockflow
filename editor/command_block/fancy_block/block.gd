@tool
extends HBoxContainer

const BlockCell = preload("res://addons/blockflow/editor/command_block/fancy_block/block_cell.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const EditorConstants = preload("res://addons/blockflow/editor/constants.gd")

class BlockButton extends BaseButton:
	# https://github.com/godotengine/godot/blob/6a13fdcae3662975c101213d47a1eb3a7db63cb3/scene/gui/button.cpp#L131
	func _get_current_stylebox() -> StyleBox:
		var stylebox:StyleBox
		
		match get_draw_mode():
			DRAW_NORMAL:
				stylebox = get_theme_stylebox("normal", "Button")
			DRAW_HOVER_PRESSED:
				stylebox = get_theme_stylebox("hover_pressed","Button")
			DRAW_PRESSED:
				stylebox = get_theme_stylebox("pressed","Button")
			DRAW_HOVER:
				stylebox = get_theme_stylebox("hover","Button")
			DRAW_DISABLED:
				stylebox = get_theme_stylebox("disabled","Button")
		
		return stylebox
	
	func _notification(what):
		var sb := _get_current_stylebox()
		match what:
			NOTIFICATION_DRAW:
				draw_style_box(sb, Rect2(Vector2(), size))
				
				if has_focus():
					draw_style_box( get_theme_stylebox("focus", "Button"), Rect2(Vector2(), size) )
	
	func _init():
		toggle_mode = true

var debug:bool = false:
	set(value):
		debug = value
		for child in get_children(true):
			child.set("debug",value)

var indent_level:int:
	set(value):
		indent_level = value
		_button.custom_minimum_size.x = 16 * indent_level
		queue_sort()

var command:CommandClass = null:
	set=set_command
var keep_selected:bool:
	set(value):
		keep_selected = value
		queue_redraw()

var layout:Dictionary

var icon_node:TextureRect
var name_node:Label

var editor:Node

var _button:BlockButton
var _sb_section:StyleBox

func select() -> void:
	_button.button_pressed = true
	_button.grab_focus()

func create_cell() -> BlockCell:
	var cell:BlockCell = BlockCell.new()
	add_child(cell)
	var _owner = owner
	if not is_instance_valid(_owner):
		_owner = self
	cell.owner = _owner
	return cell


func get_drop_section(at_position:Vector2) -> EditorConstants.DropSection:
	var drop_section:EditorConstants.DropSection = EditorConstants.DropSection.NO_ITEM
	var offset := 2
	var self_rect := Rect2(Vector2(), size)
	var above_rect := Rect2(0, 0, size.x, size.y/2-offset)
	var below_rect := Rect2(0, size.y/2+offset, size.x, size.y)
	var on_rect := Rect2(0, (size.y/2)-(size.y/3), size.x, (size.y/2)+(size.y/3))
	
	if not self_rect.has_point(at_position):
		return EditorConstants.DropSection.NO_ITEM
	
	if on_rect.has_point(at_position):
		if command.can_hold_commands:
			drop_section = EditorConstants.DropSection.ON_ITEM
		else:
			drop_section = EditorConstants.DropSection.BELOW_ITEM
	
	if below_rect.has_point(at_position):
		drop_section = EditorConstants.DropSection.BELOW_ITEM
	
	if above_rect.has_point(at_position):
		drop_section = EditorConstants.DropSection.ABOVE_ITEM
	
	return drop_section


func set_command(value:CommandClass) -> void:
	if not value:
		name_node.text = "[Unknow]"
		icon_node.texture = get_theme_icon("Unknow", "BlockflowIcons")
		name = "BlockNode"
		return
	
	command = value
	
	name_node.text = command.command_name
	icon_node.texture = command.command_icon
	
	if command.get_command_owner() is CommandClass:
		indent_level += 1

func _show_item_popup(popup:PopupMenu) -> void:
	if not popup: return
	if not editor: return
	
	var c_pos:int = command.get_command_owner().get_command_position(command)
	var c_max_size:int = command.get_command_owner().collection.size()
	var can_move_up:bool = c_pos != 0
	var can_move_down:bool = c_pos < c_max_size - 1
		
	popup.clear()
	popup.add_theme_constant_override("icon_max_width", 16)
	popup.add_item("[%s]"%command.command_name, EditorConstants.ItemPopup.NAME)
	popup.set_item_indent(
		popup.get_item_index(EditorConstants.ItemPopup.NAME),
		4
	)
	popup.set_item_disabled(
		popup.get_item_index(EditorConstants.ItemPopup.NAME),
		true
	)
	popup.set_item_icon(
		popup.get_item_index(EditorConstants.ItemPopup.NAME),
		command.command_icon
	)
	
	popup.add_item("Move up", EditorConstants.ItemPopup.MOVE_UP)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.MOVE_UP),
		EditorConstants.SHORTCUT_MOVE_UP
	)
	popup.set_item_disabled(
		popup.get_item_index(EditorConstants.ItemPopup.MOVE_UP), !can_move_up
	)
	
	popup.add_item("Move down", EditorConstants.ItemPopup.MOVE_DOWN)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.MOVE_DOWN),
		EditorConstants.SHORTCUT_MOVE_DOWN
	)
	popup.set_item_disabled(
		popup.get_item_index(EditorConstants.ItemPopup.MOVE_DOWN), !can_move_down
	)
	popup.add_separator()
	
	popup.add_item("Duplicate", EditorConstants.ItemPopup.DUPLICATE)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.DUPLICATE),
		EditorConstants.SHORTCUT_DUPLICATE
	)
	popup.add_item("Remove", EditorConstants.ItemPopup.REMOVE)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.REMOVE),
		EditorConstants.SHORTCUT_DELETE
	)
	
	popup.add_separator()
	
	popup.add_item("Copy", EditorConstants.ItemPopup.COPY)
	popup.set_item_icon(
		popup.get_item_index(EditorConstants.ItemPopup.COPY),
		get_theme_icon("ActionCopy", "EditorIcons")
	)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.COPY),
		EditorConstants.SHORTCUT_COPY
	)
	
	popup.add_item("Paste", EditorConstants.ItemPopup.PASTE)
	popup.set_item_icon(
		popup.get_item_index(EditorConstants.ItemPopup.PASTE), 
		get_theme_icon("ActionPaste", "EditorIcons")
	)
	popup.set_item_disabled(
		popup.get_item_index(EditorConstants.ItemPopup.PASTE),
		editor.command_clipboard == null
	)
	popup.set_item_shortcut(
		popup.get_item_index(EditorConstants.ItemPopup.PASTE),
		EditorConstants.SHORTCUT_PASTE
	)
	
	popup.add_separator()
	
	popup.add_item("Create Template...", EditorConstants.ItemPopup.CREATE_TEMPLATE)
	
	popup.reset_size()
	popup.position = get_global_mouse_position()
	popup.popup()

func _get_drag_data(at_position: Vector2) -> Variant:
	if not command:
		return
	
	if not command.can_be_moved:
		return
	
	var drag_data = {&"type":&"resource", &"resource":null, &"from":self}
	drag_data[&"resource"] = command
	
	var drag_preview := Button.new()
	drag_preview.text = command.command_name
	set_drag_preview(drag_preview)
	
	return drag_data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	_sb_section = null
	
	var moved_command:CommandClass = data.get(&"resource", null) as CommandClass
	if not moved_command:
		return false
	
	if moved_command == command:
		return false
	
	match get_drop_section(at_position):
		EditorConstants.DropSection.ABOVE_ITEM:
			_sb_section = get_theme_stylebox(&"section_above")
		
		EditorConstants.DropSection.ON_ITEM:
			_sb_section = get_theme_stylebox(&"section_on")
		
		EditorConstants.DropSection.BELOW_ITEM:
			_sb_section = get_theme_stylebox(&"section_below")
		_:
			_sb_section = null
	
	queue_redraw()
	
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not is_instance_valid(editor):
		return
	
	var drag_command:CommandClass = data.get(&"resource", null)
	if not drag_command:
		return
	
	match get_drop_section(at_position):
		EditorConstants.DropSection.ABOVE_ITEM:
			var prev_command:CommandClass =\
			 command.get_command_owner().get_command(max(0, command.index - 1))
			
			if prev_command == drag_command:
				# No need to move
				return
			
			var new_index:int = command.index - int(command.index >= drag_command.index)
			editor.move_command(drag_command, new_index, null, command.get_command_owner())
		
		EditorConstants.DropSection.ON_ITEM:
			if not command.can_hold_commands:
				push_error("!can_hold_commands == true")
				return
			
			editor.move_command(drag_command, -1, null, command)
		
		EditorConstants.DropSection.BELOW_ITEM:
			if command.can_hold_commands:
				editor.move_command(drag_command, 0, null, command)
				return
			
			var next_command:CommandClass
			
			var new_index:int = command.index + int(command.index < drag_command.index)
			
			if command.get_command_owner() != drag_command.get_command_owner():
				new_index = command.index + 1
			
			editor.move_command(drag_command, new_index, null, command.get_command_owner())

func _gui_input(event:InputEvent) -> void:
	if EditorConstants.SHORTCUT_OPEN_MENU.matches_event(event) and event.is_released():
		_button.button_pressed = true
		_show_item_popup(editor.get("command_popup"))
		accept_event()


func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			fit_child_in_rect(_button, Rect2(0, 0, size.x, size.y))
		NOTIFICATION_CHILD_ORDER_CHANGED:
			notify_property_list_changed()
			update_configuration_warnings()
		
		NOTIFICATION_DRAW:
			if _sb_section:
				draw_style_box(_sb_section, Rect2(Vector2(), size))
			
			if keep_selected:
				draw_style_box(get_theme_stylebox("selected", "Tree"), Rect2(Vector2(), size))
		
		NOTIFICATION_DRAG_BEGIN:
			_button.disabled = true
			queue_redraw()
		
		NOTIFICATION_DRAG_END:
			_sb_section = null
			_button.disabled = false
			queue_redraw()
		
		NOTIFICATION_MOUSE_EXIT:
			_sb_section = null
			queue_redraw()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for child in get_children():
		var c = child as BlockCell
		if not c:
			warnings.append("Child '%s' is not CellBlock type. This may cause layout incongruences."%child.name)
	return warnings

func _set(property: StringName, value: Variant) -> bool:
	if property == "advanced/debug":
		debug = value
		return true
	
	return false


func _get(property: StringName) -> Variant:
	if property == "advanced/debug":
		return debug
	
	if property.begins_with("advanced/cells"):
		var p := property.trim_prefix("advanced/cells/")
		var child_idx:int = -1
		if p.is_valid_int():
			child_idx = p.to_int()
		
		if child_idx > -1 and child_idx <= get_child_count():
			return get_child(child_idx)
		
	return null


func _get_property_list() -> Array:
	var p := []
	
	p.append({
		"name":"advanced/debug",
		"type":TYPE_BOOL,
		"usage":PROPERTY_USAGE_EDITOR
	})
	
	for child_idx in get_child_count(false):
		p.append({
			"name":"advanced/cells/"+str(child_idx),
			"type":TYPE_OBJECT,
			"usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY,
			"hint":PROPERTY_HINT_NODE_TYPE
			})
	return p

func _init():
	name = "BlockNode"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme_type_variation = "Block"
	
	_button = BlockButton.new()
	_button.mouse_filter = Control.MOUSE_FILTER_PASS
	_button.focus_mode = Control.FOCUS_ALL
	
	var icon_cell := BlockCell.new()
	icon_cell.name = &"IconCell"
	icon_node = TextureRect.new()
	icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	icon_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_node.custom_minimum_size = Vector2(16,16)
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_cell.add_child(icon_node)
	
	var name_cell := BlockCell.new()
	name_cell.name = &"NameCell"
	name_node = Label.new()
	name_node.text = "[Command Name]"
	name_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_cell.add_child(name_node)
	
	add_child(_button, false, Node.INTERNAL_MODE_FRONT)
	add_child(icon_cell, false, Node.INTERNAL_MODE_FRONT)
	add_child(name_cell, false, Node.INTERNAL_MODE_FRONT)
	
	debug = false
	command = null
