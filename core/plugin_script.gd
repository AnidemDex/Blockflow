@tool
extends EditorPlugin

const Blockflow = preload("res://addons/blockflow/blockflow.gd")
const BlockEditor = preload("res://addons/blockflow/editor/editor.gd")
const InspectorTools = preload("res://addons/blockflow/editor/inspector/inspector_tools.gd")
const CommandInspector = preload("res://addons/blockflow/editor/inspector/command_inspector.gd")
const CommandCallInspector = preload("res://addons/blockflow/editor/inspector/call_inspector.gd")
const BlockflowDebugger = preload("res://addons/blockflow/debugger/blockflow_debugger.gd")

const Constants = preload("res://addons/blockflow/core/constants.gd")
const EditorConstants = preload("res://addons/blockflow/editor/constants.gd")


var block_editor:BlockEditor

var last_edited_object:Object
var last_handled_object:Object


var node_selector:InspectorTools.NodeSelector
var method_selector:InspectorTools.MethodSelector

var command_inspector:CommandInspector
var command_call_inspector:CommandCallInspector

var editor_toaster:Node

var debugger:BlockflowDebugger

var theme:Theme = load(EditorConstants.DEFAULT_THEME_PATH) as Theme

var command_record:Blockflow.CommandRecord

func toast(message:String, severity:int = 0, tooltip:String = ""):
	if not is_inside_tree():
		return
	if not is_instance_valid(editor_toaster):
		return
	
	editor_toaster.call("_popup_str", message, severity, tooltip)

func _enter_tree():
	_define_toaster()
	block_editor.toast_callback = toast
	
	get_editor_interface().get_editor_main_screen().add_child(block_editor)
	get_editor_interface().get_base_control().add_child(node_selector)
	get_editor_interface().get_base_control().add_child(method_selector)
	_make_visible(false)
	
	add_inspector_plugin(command_inspector)
	add_inspector_plugin(command_call_inspector)
	
	add_debugger_plugin(debugger)


func _handles(object: Object) -> bool:
	var condition:bool = false
	condition =\
	(object is Blockflow.CollectionClass)
	
	last_handled_object = object
	
	return condition


func _edit(object: Object) -> void:
	block_editor.editor_undoredo = get_undo_redo()
	block_editor.edit(object)
	last_edited_object = object


func _make_visible(visible: bool) -> void:
	if is_instance_valid(block_editor):
		block_editor.visible = visible
	return

func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return Constants.NAME

func _get_plugin_icon():
	return theme.get_icon("plugin_icon_flat", "PluginIcons")

func _save_external_data() -> void:
	queue_save_layout()

func _get_window_layout(configuration: ConfigFile) -> void:
	block_editor.save_layout()

func _define_toaster() -> void:
	var dummy = Control.new()
	dummy.name = "Dummy"
	var d_btn = add_control_to_bottom_panel(dummy, "test")
	d_btn.name = "dummy test"

	for child in d_btn.get_parent().get_parent().get_children():
		if child.get_class() == "EditorToaster":
			editor_toaster = child
			break

	remove_control_from_bottom_panel(dummy)
	dummy.queue_free()

func _exit_tree():
	queue_save_layout()
	block_editor.queue_free()
	
	
	remove_inspector_plugin(command_inspector)
	remove_inspector_plugin(command_call_inspector)
	command_inspector = null
	command_call_inspector = null
	
	remove_debugger_plugin(debugger)


func _init() -> void:
	block_editor = BlockEditor.new()
	block_editor.edit_callback = Callable(get_editor_interface(), "edit_resource")
	block_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	block_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
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
	
	debugger = BlockflowDebugger.new()
	
	command_record = Blockflow.CommandRecord.get_record()
	project_settings_changed.connect(command_record.reload_from_project_settings)
	
	# Add the plugin to the list when we're created as soon as possible.
	# Existing doesn't mean that plugin is ready, be careful with that.
	Engine.set_meta(Constants.PLUGIN_NAME, self)
