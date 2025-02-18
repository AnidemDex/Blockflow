@tool
extends PanelContainer

const CollectionClass = preload("res://addons/blockflow/collection.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CCollectionClass = preload("res://addons/blockflow/command_collection.gd")
const Block = preload("res://addons/blockflow/editor/command_block/fancy_block/block.gd")
const BlockGenericPath = "res://addons/blockflow/editor/command_block/fancy_block/generic_block.tscn"

signal display_finished
signal command_selected(command)

var displayed_commands:Array
var current_collection:CollectionClass

var selected_item:Block

var _group:ButtonGroup
var _root:VBoxContainer
var _sc:ScrollContainer
var _vb:VBoxContainer

func clear() -> void:
	if is_instance_valid(_root):
		_root.queue_free()
		_sc.remove_child(_root)
	_create_root()

func display(object:Object) -> void:
	clear()
	
	if object is CommandClass:
		_display_command(object)
		return
	
	if object is CCollectionClass:
		_display_command_collection(object)
		return
	
	if object is CollectionClass:
		_display_collection(object)
		return


func _display_command(command:CommandClass) -> void:
	var blocks:Array[Node] = []
	
	_create_root()
	current_collection = command
	_build_fake_tree(current_collection, blocks)
	
	for block in blocks:
		_root.add_child(block)

func _display_command_collection(command_collection:CCollectionClass) -> void:
	var blocks:Array[Node] = []
	
	_create_root()
	current_collection = command_collection
	_group = ButtonGroup.new()
	_group.pressed.connect(_group_pressed)
	_build_fake_tree(current_collection, blocks,0)
	
	for block in blocks:
		_root.add_child(block)
	
	display_finished.emit.call_deferred()

func _display_collection(collection:CollectionClass) -> void:
	_create_root()
	pass

func _build_fake_tree(curr_c, blocks, itr_lvl=0):
	var generic_block_scene = load(BlockGenericPath) as PackedScene
	if not generic_block_scene:
		push_error("We can't create default block scene")
	
	if curr_c is CommandClass:
		if curr_c.get_command_owner() is CommandClass:
			itr_lvl += 1
	
	for command in curr_c:
		var block:Block
		if not generic_block_scene:
			block = Block.new()
		else:
			block = generic_block_scene.instantiate()
		
		block._button.button_group = _group
		block.indent_level = itr_lvl
		block.command = command
		command.editor_block = block
		blocks.append(block)
		
		if not command.is_empty():
			_build_fake_tree(command, blocks, itr_lvl)

func _create_root() -> void:
	if is_instance_valid(_root):
		if not _root.is_queued_for_deletion():
			return
	
	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.add_child(_root)


func _group_pressed(button:BaseButton) -> void:
	command_selected.emit(button.get_parent().get("command"))
	selected_item = button.get_parent()


func _init():
	_vb = VBoxContainer.new()
	_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_vb)
	
	_sc = ScrollContainer.new()
	_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vb.add_child(_sc)
