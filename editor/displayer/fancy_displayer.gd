@tool
extends PanelContainer

const CollectionClass = preload("res://addons/blockflow/collection.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CCollectionClass = preload("res://addons/blockflow/command_collection.gd")
const Block = preload("res://addons/blockflow/editor/command_block/fancy_block/block.gd")

var displayed_commands:Array
var current_collection:CollectionClass

var _group:ButtonGroup
var _root:VBoxContainer
var _sc:ScrollContainer
var _vb:VBoxContainer

func _display(object:Object) -> void:
	if object is CommandClass:
		_display_command(object)
	
	if object is CCollectionClass:
		_display_command_collection(object)
	
	if object is CollectionClass:
		_display_collection(object)


func _display_command(command:CommandClass) -> void:
	var blocks:Array[Node] = []
	
	current_collection = command
	_build_fake_tree(current_collection, blocks)
	
	for block in blocks:
		_root.add_child(block)

func _display_command_collection(command_collection:CCollectionClass) -> void:
	var blocks:Array[Node] = []
	
	current_collection = command_collection
	_group = ButtonGroup.new()
	_build_fake_tree(current_collection, blocks,0)
	
	for block in blocks:
		_root.add_child(block)

func _display_collection(collection:CollectionClass) -> void:
	pass

func _build_fake_tree(curr_c, blocks, itr_lvl=0):
	if curr_c is CommandClass:
		if curr_c.get_command_owner() is CommandClass:
			itr_lvl += 1
	
	for command in curr_c:
		var block := Block.new()
		block._button.button_group = _group
		block.indent_level = itr_lvl
		block.command = command
		blocks.append(block)
		
		if not command.is_empty():
			_build_fake_tree(command, blocks, itr_lvl)

func _init():
	_vb = VBoxContainer.new()
	_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_vb)
	
	_sc = ScrollContainer.new()
	_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vb.add_child(_sc)
	
	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.add_child(_root)
