@tool
extends "res://addons/blockflow/editor/inspector/inspector_tools.gd"

func _can_handle(object: Object) -> bool:
	return object is CollectionClass

func _parse_end(object: Object) -> void:
	var collection := object as CollectionClass
	if collection.is_empty():
		return
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 254)
	
	var displayer := Tree.new()
	sc.add_child(displayer)
	displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	displayer.custom_minimum_size = Vector2(0, 254)
	
	var root := displayer.create_item()
	root.set_text(0,"Internal collection")
	
	for child in collection:
		var item := displayer.create_item(root)
		item.set_text(0, str(child.get("command_name")))
	
	root.collapsed = true
	
	add_custom_control(sc)
