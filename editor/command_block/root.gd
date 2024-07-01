@tool
extends "res://addons/blockflow/editor/command_block/block.gd"

const ICON = preload("res://addons/blockflow/icons/timeline.svg")

var collection:CollectionClass:
	set(value):
		if value == collection:
			return
		if collection and collection.changed.is_connected(update):
			collection.changed.disconnect(update)
		
		collection = value
		set_metadata(0, collection)
		
		if not collection:
			return
		
		collection.changed.connect(update)
		update()


func update() -> void:
	var collection_name:String = collection.resource_name
	if collection_name.is_empty():
		collection_name = collection.resource_path.get_file()
	
	var icon_min_size:int = get_tree().get_theme_constant("icon_min_size", "BlockEditor")
	for i in get_tree().columns:
		set_expand_right(i, false)
		set_icon_max_width(i, icon_min_size)
	
	set_text(ColumnPosition.HINT_COLUMN, collection_name)
	set_text_alignment(ColumnPosition.HINT_COLUMN, HORIZONTAL_ALIGNMENT_CENTER)
	set_text(ColumnPosition.INDEX_COLUMN, str(collection.get_command_count()))
	set_icon(0, ICON)


func set_command(_value) -> void:
	command = null
	push_error("Can't assign a command to root item!")

func _init():
	disable_folding = true
	custom_minimum_height = 32
