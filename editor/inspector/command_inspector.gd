@tool
extends "res://addons/blockflow/editor/inspector/inspector_tools.gd"

class TargetProperty extends EditorProperty:
	var editor_plugin:EditorPlugin
	var node_selector:NodeSelector
	var selector:Button
	var revert:Button
	
	func _update_property() -> void:
		var property:String = get_edited_property()
		var object:Object = get_edited_object()
		var current_value:NodePath = object[property]
		var current_scene:Node = editor_plugin.get_editor_interface().get_edited_scene_root()
		
		var text:String = current_value
		var icon:Texture = null
		revert.icon = get_theme_icon("Reload", "EditorIcons")
		revert.hide()
		
		if text.is_empty():
			text = "[None]"
		else:
			revert.show()
			if is_instance_valid(current_scene):
				var node:Node = current_scene.get_node_or_null(current_value)
				if is_instance_valid(node):
					icon = get_theme_icon(node.get_class(), "EditorIcons")
				if text == ".":
					text = "[Scene Root]"
		
		selector.tooltip_text = "NodePath(\"%s\")"%current_value
		selector.text = text
		selector.icon = icon
		
	
	func _selector_pressed() -> void:
		node_selector.popup_centered_ratio(0.25)
		node_selector.confirmed.connect(_selector_confirmed, CONNECT_ONE_SHOT)
	
	func _selector_confirmed() -> void:
		if not node_selector.selected_item:
			return
		var path:NodePath = node_selector.selected_item.get_metadata(0)
		emit_changed(get_edited_property(), path)
	
	func _revert_pressed() -> void:
		emit_changed(get_edited_property(), NodePath())
	
	func _init() -> void:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 0)
		add_child(hb)
		
		revert = Button.new()
		revert.flat = true
		revert.pressed.connect(_revert_pressed)
		hb.add_child(revert)
		
		selector = Button.new()
		selector.clip_text = true
		selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.pressed.connect(_selector_pressed)
		add_focusable(selector)
		hb.add_child(selector)

var node_selector:NodeSelector
var _should_ignore:bool = false

func _can_handle(object: Object) -> bool:
	return object is Command

func _parse_begin(object: Object) -> void:
	_should_ignore = false


func _parse_category(object: Object, category: String) -> void:
	if category == "Resource":
		_should_ignore = true
	if _should_ignore:
		var dummy = PrevNodeVanisher.new()
		add_custom_control(dummy)


func _parse_group(object: Object, group: String) -> void:
	if _should_ignore:
		var dummy = GroupVanisher.new()
		add_custom_control(dummy)


func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: PropertyUsageFlags,
	wide: bool ) -> bool:
	
	if name == "target":
		var target_property = TargetProperty.new()
		target_property.editor_plugin = editor_plugin
		target_property.node_selector = node_selector
		add_property_editor(name, target_property)
		return true
	
	return _should_ignore

func _parse_end(object: Object) -> void:
	if _should_ignore:
		var dummy = PrevNodeVanisher.new()
		add_custom_control(dummy)
	_should_ignore = false
