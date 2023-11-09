@tool
extends EditorInspectorPlugin

var editor_plugin:EditorPlugin
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CollectionClass = preload("res://addons/blockflow/collection.gd")

class NodeSelector extends ConfirmationDialog:
	var editor_plugin:EditorPlugin
	var fake_tree:Tree
	var line_edit:LineEdit
	var node_path:NodePath
	
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
			line_edit.text = ""
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
		line_edit.text = fake_tree.get_selected().get_metadata(0)
		get_ok_button().disabled = line_edit.text.is_empty()
		node_path = NodePath(line_edit.text)
	
	func _fake_tree_item_activated() -> void:
		node_path = NodePath(fake_tree.get_selected().get_metadata(0))
		confirmed.emit()
		hide()
	
	func _line_edit_text_changed(new_text: String) -> void:
		fake_tree.deselect_all()
		get_ok_button().disabled = new_text.is_empty()
		node_path = NodePath(new_text)
	
	func _init() -> void:
		name = "NodeSelector"
		title = "Node Selector"
		
		var vb := VBoxContainer.new()
		vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(vb)
		
		line_edit = LineEdit.new()
		line_edit.placeholder_text = "Input NodePath"
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.text_changed.connect(_line_edit_text_changed)
		vb.add_child(line_edit)
		register_text_enter(line_edit)

		fake_tree = Tree.new()
		fake_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fake_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fake_tree.item_selected.connect(_fake_tree_item_selected)
		fake_tree.item_activated.connect(_fake_tree_item_activated)
		vb.add_child(fake_tree)

class PrevNodeVanisher extends Control:
	func _ready() -> void:
		get_parent().get_child(get_index()-1).set("visible", false)
		queue_free()

class GroupVanisher extends Control:
	func _ready() -> void:
		get_parent().get_parent().set("visible", false)
		queue_free()

# https://github.com/godotengine/godot/blob/4.0.3-stable/editor/editor_inspector.cpp
class FakeCategory extends Control:
	var icon:Texture
	var label:String
	var bg_color:Color = Color.BLACK
	
	func _get_minimum_size() -> Vector2:
		var font := get_theme_font("bold","EditorFonts")
		var font_size := get_theme_font_size("bold_size", "EditorFonts")
		
		var ms := Vector2()
		ms.y = font.get_height(font_size)
		
		if icon:
			ms.y = max(ms.y, 16)
		
		ms.y += get_theme_constant("v_separation", "Tree")
		return ms
	
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_ENTER_TREE:
				pass
			NOTIFICATION_DRAW:
				var sb := get_theme_stylebox("bg", "EditorInspectorCategory")
				draw_style_box(sb, Rect2(Vector2(), size))
				
				var font := get_theme_font("bold","EditorFonts")
				var font_size := get_theme_font_size("bold_size", "EditorFonts")
				
				var hs := get_theme_constant("h_separation", "Tree")
				var w := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
				
				if icon:
					w += hs + 16
				
				var ofs := (size.x - w) / 2
				
				if icon:
					draw_texture_rect(icon,
					Rect2(
						ofs, (size.y - 16) / 2, 16, 16
						),
					false)
					ofs += hs + 16
				
				var c := get_theme_color("font_color","Tree")
				draw_string(
					font,
					Vector2(
						ofs, 
						font.get_ascent(font_size) + ( (size.y - font.get_height(font_size)) / 2 )
						).floor(),
					label,
					HORIZONTAL_ALIGNMENT_LEFT,
					size.x,
					font_size,
					c
					)
				
				
			NOTIFICATION_READY:
				var parent:Node = get_parent()
				if is_instance_valid(parent):
					if get_index() != 0:
						var category := parent.get_child(get_index()-1) as Control
						category.set("visible", false)
				
				if icon == null:
					icon = get_theme_icon("Object", "EditorIcons")
				
				if bg_color == Color.BLACK:
					bg_color = get_theme_color("prop_category", "Editor")
				
				queue_redraw()


class MethodSelector extends ConfirmationDialog:
	
	var fake_tree:Tree
	var method_tree:Tree
	var editor_plugin:EditorPlugin
	var disable_node_tree:bool = false
	var script_methods_only:CheckButton
	
	func get_selected_path() -> NodePath:
		var path:NodePath
		var item := fake_tree.get_selected()
		if item:
			path = item.get_metadata(0)
		return path
	
	func get_selected_node() -> Node:
		var path:NodePath = get_selected_path()
		if path.is_empty():
			return
		
		var selected_node:Node = editor_plugin.get_editor_interface().get_edited_scene_root().get_node_or_null(path)
		if not is_instance_valid(selected_node):
			return null
		
		return selected_node
	
	func get_selected_method() -> StringName:
		var method:StringName
		var selected_item := method_tree.get_selected()
		if selected_item:
			method = selected_item.get_metadata(0)["name"]
		return method
	
	func get_selected_signature() -> Dictionary:
		var method_data:Dictionary
		var selected_item := method_tree.get_selected()
		if selected_item:
			method_data = selected_item.get_metadata(0)
		return method_data
	
	func _recursive_node_tree(ref_item:TreeItem, ref_node:Node, root_node:Node) -> void:
		ref_item.set_text(0, ref_node.name)
		ref_item.set_icon(0, get_theme_icon(ref_node.get_class(), "EditorIcons"))
		ref_item.set_metadata(0, root_node.get_path_to(ref_node))
		ref_item.set_selectable(0, !disable_node_tree)
		
		for child in ref_node.get_children():
			var item:TreeItem = ref_item.create_child()
			_recursive_node_tree(item, child, root_node)
	
	func _generate_method_list() -> void:
		method_tree.clear()
		var disabled_color := get_theme_color("accent_color", "Editor") * 0.7
		var ref_node:Node = get_selected_node()
		if not is_instance_valid(ref_node): return
		
		var root_item:TreeItem = method_tree.create_item()
		var script_instance:Script = ref_node.get_script() as Script
		if script_instance:
			var methods := script_instance.get_script_method_list()
			var script_item := method_tree.create_item(root_item)
			script_item.set_text(0, "Attached Script")
			script_item.set_icon(0, get_theme_icon("Script", "EditorIcons"))
			script_item.set_selectable(0, false)
			
			if methods.is_empty():
				script_item.set_custom_color(0, disabled_color)
			else:
				_create_method_tree_items(methods, script_item)
		
		if script_methods_only.button_pressed:
			return
		
		var current_class:StringName = ref_node.get_class()
		while current_class != "":
			var class_item := method_tree.create_item(root_item)
			class_item.set_text(0, current_class)
			var icon := get_theme_icon("Node", "EditorIcons")
			if has_theme_icon(current_class, "EditorIcons"):
				icon = get_theme_icon(current_class, "EditorIcons")
			class_item.set_icon(0, icon)
			class_item.set_selectable(0, false)
			
			var methods:Array = ClassDB.class_get_method_list(current_class, true)			
			if methods.is_empty():
				class_item.set_custom_color(0, disabled_color)
			else:
				_create_method_tree_items(methods, class_item)
			
			current_class = ClassDB.get_parent_class(current_class)
	
	#https://github.com/godotengine/godot/blob/4.0.2-stable/editor/connections_dialog.cpp#L264
	func _create_method_tree_items(methods:Array, ref_item:TreeItem) -> void:
		for method_data in methods:
			var method_item := method_tree.create_item(ref_item)
			method_item.set_text(0, get_signature(method_data))
			method_item.set_metadata(0, method_data)
	
	# https://github.com/godotengine/godot/blob/4.0.2-stable/editor/connections_dialog.cpp#L499
	func get_signature(method_data:Dictionary) -> String:
		var signature := PackedStringArray()
		signature.append(method_data.name)
		signature.append("(")
		
		for i in method_data.args.size():
			if i > 0:
				signature.append(", ")
			
			var property_info:Dictionary = method_data.args[i]
			var type_name:String = "var"
			if property_info.type == TYPE_OBJECT and !property_info["class_name"].is_empty():
				type_name = property_info["class_name"]
			else:
				# TODO: We need Variant.get_type_name to
				# know the type name of Variant.Type
				# Technically we can use a giant enum but Zzz
				type_name = "" # Yeet the type
			
			if property_info.name.is_empty():
				signature.append("arg %s"%i)
			else:
				signature.append(property_info.name)
			if not type_name.is_empty():
				signature.append(": "+type_name)
		
		signature.append(")")
		return "".join(signature)
	
	func _fake_tree_item_selected() -> void:
		_generate_method_list()
	
	
	func _method_tree_item_selected() -> void:
		get_ok_button().disabled = get_selected_method().is_empty()
	
	
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_VISIBILITY_CHANGED:
				get_ok_button().disabled = true
				
				if not visible:
					return
				fake_tree.clear()
				fake_tree.deselect_all()
				method_tree.clear()
				method_tree.deselect_all()
				
				var scene_root:Node =\
				editor_plugin.get_editor_interface().get_edited_scene_root()
				if not is_instance_valid(scene_root):
					return
				
				var root:TreeItem = fake_tree.create_item()
				root.set_text(0, scene_root.name)
				root.set_icon(0, get_theme_icon(scene_root.get_class(), "EditorIcons"))
				_recursive_node_tree(root, scene_root, scene_root)
	
	func _init() -> void:
		title = "Method Selector"
		var hb := HBoxContainer.new()
		add_child(hb)
		
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		
		var label := Label.new()
		label.text = "From Node:"
		vb.add_child(label)
		
		fake_tree = Tree.new()
		fake_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fake_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fake_tree.item_selected.connect(_fake_tree_item_selected)
		vb.add_child(fake_tree)
		
		vb = VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		
		label = Label.new()
		label.text = "Call Method:"
		vb.add_child(label)
		
		method_tree = Tree.new()
		method_tree.hide_root = true
		method_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		method_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		method_tree.item_selected.connect(_method_tree_item_selected)
		vb.add_child(method_tree)
		
		script_methods_only = CheckButton.new()
		script_methods_only.toggle_mode = true
		script_methods_only.set_pressed_no_signal(true)
		script_methods_only.text = "Script Methods Only"
		script_methods_only.toggled.connect(_generate_method_list)
		vb.add_child(script_methods_only)
