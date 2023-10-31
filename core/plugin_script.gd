@tool
extends EditorPlugin

const TimelineEditor = preload("res://addons/blockflow/editor/editor.gd")
const TimelineConverter = preload("res://addons/blockflow/timeline_converter.gd")
const InspectorTools = preload("res://addons/blockflow/editor/inspector/inspector_tools.gd")
const CommandInspector = preload("res://addons/blockflow/editor/inspector/command_inspector.gd")
const CommandCallInspector = preload("res://addons/blockflow/editor/inspector/call_inspector.gd")

var timeline_editor:TimelineEditor
var last_edited_timeline:CommandCollection
var last_handled_object:Object
var timeline_converter:TimelineConverter
var node_selector:InspectorTools.NodeSelector
var method_selector:InspectorTools.MethodSelector
var command_inspector:CommandInspector
var command_call_inspector:CommandCallInspector

func _enter_tree():
	get_editor_interface().get_editor_main_screen().add_child(timeline_editor)
	get_editor_interface().get_base_control().add_child(node_selector)
	get_editor_interface().get_base_control().add_child(method_selector)
	_make_visible(false)
	
	add_resource_conversion_plugin(timeline_converter)
	add_inspector_plugin(command_inspector)
	add_inspector_plugin(command_call_inspector)


func _handles(object: Object) -> bool:
	var o:Resource = object as Resource
	if not o: return false
	var condition:bool = false
	condition = is_instance_of(object, CommandCollection) or is_instance_of(object, Command)
	
	last_handled_object = object
	
	return condition


func _edit(object: Object) -> void:
	if object is CommandCollection:
		timeline_editor.editor_undoredo = get_undo_redo()
		timeline_editor.edit_timeline(object as CommandCollection)
		last_edited_timeline = object


func _make_visible(visible: bool) -> void:
	if is_instance_valid(timeline_editor):
		timeline_editor.visible = visible
	return

func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Block Editor"

# TODO:
# Replace with custom icon
func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")


func _exit_tree():
	timeline_editor.queue_free()
	
	remove_resource_conversion_plugin(timeline_converter)
	timeline_converter = null
	
	remove_inspector_plugin(command_inspector)
	remove_inspector_plugin(command_call_inspector)
	command_inspector = null
	command_call_inspector = null


func _init() -> void:
	timeline_editor = TimelineEditor.new()
	timeline_editor.edit_callback = Callable(get_editor_interface(), "edit_resource")
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	timeline_converter = TimelineConverter.new()
	command_inspector = CommandInspector.new()
	
	node_selector = InspectorTools.NodeSelector.new()
	node_selector.editor_plugin = self
	tree_exited.connect(node_selector.queue_free)
	
	method_selector = InspectorTools.MethodSelector.new()
	method_selector.editor_plugin = self
	tree_exited.connect(method_selector.queue_free)
	
	command_inspector.editor_plugin = self
	command_inspector.node_selector = node_selector
	
	command_call_inspector = CommandCallInspector.new()
	command_call_inspector.editor_plugin = self
