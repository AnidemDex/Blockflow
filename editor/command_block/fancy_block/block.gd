@tool
extends HBoxContainer

const BlockCell = preload("res://addons/blockflow/editor/command_block/fancy_block/block_cell.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

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

var layout:Dictionary

var icon_node:TextureRect
var name_node:Label

var _button:BlockButton

func create_cell() -> BlockCell:
	var cell:BlockCell = BlockCell.new()
	add_child(cell)
	var _owner = owner
	if not is_instance_valid(_owner):
		_owner = self
	cell.owner = _owner
	return cell


func set_command(value:CommandClass) -> void:
	if not value:
		name_node.text = "[Unknow]"
		icon_node.texture = get_theme_icon("Unknow", "BlockflowIcons")
		return
	
	command = value
	
	name_node.text = command.command_name
	icon_node.texture = command.command_icon
	
	if command.get_command_owner() is CommandClass:
		indent_level += 1

func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			fit_child_in_rect(_button, Rect2(0, 0, size.x, size.y))
		NOTIFICATION_CHILD_ORDER_CHANGED:
			notify_property_list_changed()
			update_configuration_warnings()


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
	add_theme_constant_override("separation", 0)
	
	_button = BlockButton.new()
	
	var icon_cell := BlockCell.new()
	icon_cell.name = &"IconCell"
	icon_node = TextureRect.new()
	icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	icon_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_node.custom_minimum_size = Vector2(16,16)
	icon_cell.add_child(icon_node)
	
	var name_cell := BlockCell.new()
	name_cell.name = &"NameCell"
	name_node = Label.new()
	name_node.text = "[Command Name]"
	name_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_cell.add_child(name_node)
	
	add_child(_button, false, Node.INTERNAL_MODE_FRONT)
	add_child(icon_cell, false, Node.INTERNAL_MODE_FRONT)
	add_child(name_cell, false, Node.INTERNAL_MODE_FRONT)
	
	debug = false
	command = null
	
	#get_window().theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
