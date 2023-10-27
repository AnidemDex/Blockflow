@tool
extends EditorInspectorPlugin

var editor_plugin:EditorPlugin

class NodeSelector extends ConfirmationDialog:
	var editor_plugin:EditorPlugin
	var fake_tree:Tree
	var selected_item:TreeItem
	
	func _recursive_create(ref_item:TreeItem, ref_node:Node, root_node:Node) -> void:
		ref_item.set_text(0, ref_node.name)
		ref_item.set_icon(0, get_theme_icon(ref_node.get_class(), "EditorIcons"))
		ref_item.set_metadata(0, root_node.get_path_to(ref_node))
		
		for child in ref_node.get_children():
			var item:TreeItem = ref_item.create_child()
			_recursive_create(item, child, root_node)
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_VISIBILITY_CHANGED:
			if not visible:
				return
			
			fake_tree.clear()
			fake_tree.deselect_all()
			get_ok_button().disabled = true
			var scene_root:Node =\
			editor_plugin.get_editor_interface().get_edited_scene_root()
			if not is_instance_valid(scene_root):
				return
			
			var root:TreeItem = fake_tree.create_item()
			root.set_text(0, scene_root.name)
			root.set_icon(0, get_theme_icon(scene_root.get_class(), "EditorIcons"))
			_recursive_create(root, scene_root, scene_root)
	
	func _fake_tree_item_selected() -> void:
		selected_item = fake_tree.get_selected()
		get_ok_button().disabled = selected_item == null
	
	func _fake_tree_item_activated() -> void:
		selected_item = fake_tree.get_selected()
		confirmed.emit()
		hide()
	
	func _init() -> void:
		name = "NodeSelector"
		title = "Node Selector"
		
		fake_tree = Tree.new()
		fake_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fake_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fake_tree.item_selected.connect(_fake_tree_item_selected)
		fake_tree.item_activated.connect(_fake_tree_item_activated)
		add_child(fake_tree)

class PrevNodeVanisher extends Control:
	func _ready() -> void:
		get_parent().get_child(get_index()-1).set("visible", false)
		queue_free()

class GroupVanisher extends Control:
	func _ready() -> void:
		get_parent().get_parent().set("visible", false)
		queue_free()
