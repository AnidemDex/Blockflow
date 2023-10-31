@tool
extends "res://addons/blockflow/editor/inspector/inspector_tools.gd"

const CommandCall = preload("res://addons/blockflow/commands/command_call.gd")

class MethodSelectorProperty extends EditorProperty:
	var editor_plugin:EditorPlugin
	var method_selector:MethodSelector
	var method_button:Button
	var args_container:VBoxContainer
	var manual_edit:Button
	
	func _update_property() -> void:
		var edited_object:CommandCall = get_edited_object()
		var current_method:String = edited_object.method
		var current_target:NodePath = edited_object.target
		var text:String = ""
		var icon:Texture = get_theme_icon("Node", "EditorIcons")
		
		if current_method.is_empty():
			text = "[Select a Method]"
			icon = null
		else:
			if str(current_target) == ".":
				text = "[Scene Root]."
			if not current_target.is_empty():
				text = str(current_target) + "."
			text += current_method 
		
		var scene_root:Node = editor_plugin.get_editor_interface().get_edited_scene_root()
		
		if is_instance_valid(scene_root):
			var target_node:Node = scene_root.get_node_or_null(current_target)
			if target_node:
				if has_theme_icon(target_node.get_class(), "EditorIcons"):
					icon = get_theme_icon(target_node.get_class(), "EditorIcons")
		
		method_button.text = text
		method_button.icon = icon
		
		method_button.visible = !manual_edit.button_pressed
	
	func _method_button_pressed() -> void:
		method_selector.confirmed.connect(_method_selector_confirmed, CONNECT_ONE_SHOT)
		method_selector.popup_centered_ratio(0.5)
	
	func _method_selector_confirmed() -> void:
		var selected_method := method_selector.get_selected_method()
		var selected_path := method_selector.get_selected_path()
		
		emit_changed("target", selected_path)
		emit_changed("method", selected_method)
	
	func _manual_edit_toggled(button_pressed:bool) -> void:
		get_edited_object().set_meta("__editor_override_property__", !button_pressed)
		get_edited_object().notify_property_list_changed()
	
	func _enter_tree() -> void:
		method_selector = editor_plugin.method_selector
		manual_edit.icon = get_theme_icon("Edit", "EditorIcons")
		manual_edit.set_pressed_no_signal(!get_edited_object().get_meta("__editor_override_property__", true))
	
	func _init() -> void:
		manual_edit = Button.new()
		manual_edit.toggle_mode = true
		manual_edit.text = "Edit Method"
		manual_edit.tooltip_text = "Edit"
		manual_edit.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		manual_edit.toggled.connect(_manual_edit_toggled, CONNECT_DEFERRED)
		add_child(manual_edit)
		
		var vb := VBoxContainer.new()
		add_child(vb)
		set_bottom_editor(vb)
		
		method_button = Button.new()
		method_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		method_button.pressed.connect(_method_button_pressed)
		vb.add_child(method_button)
		add_focusable(method_button)
		
		args_container = VBoxContainer.new()
		vb.add_child(args_container)


func _can_handle(object: Object) -> bool:
	return object is CommandCall

func _parse_property(
	object: Object,
	type, # For some reason, setting it typed is inconsistent
	name: String,
	hint_type,
	hint_string: String,
	usage_flags,
	wide: bool ) -> bool:
		if not object:
			# For some reason there's no object?
			return false
		
		var override_property = object.get_meta("__editor_override_property__", true)
		if name == "method":
			var method_selector_prop := MethodSelectorProperty.new()
			method_selector_prop.editor_plugin = editor_plugin
			add_property_editor_for_multiple_properties("Call method:", ["method", "args", "target"], method_selector_prop)
			return override_property
		
		if name == "args":
			return override_property
		
		if name == "target":
			return override_property
		
		return false
