@tool
extends EditorPlugin

const TimelineEditor = preload("res://addons/blockflow/editor/editor.gd")

var timeline_editor:TimelineEditor

func _enter_tree():
	get_editor_interface().get_editor_main_screen().add_child(timeline_editor)
	_make_visible(false)


func _handles(object: Object) -> bool:
	var o:Timeline = object as Timeline
	
	if o == null: return false
	
	if o.resource_path.is_empty(): return false
	
	return o is Timeline


func _edit(object: Object) -> void:
	timeline_editor.editor_undoredo = get_undo_redo()
	timeline_editor.edit_timeline(object as Timeline)
	


func _make_visible(visible: bool) -> void:
	if is_instance_valid(timeline_editor):
		timeline_editor.visible = visible
	return

func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "TimelineEditor"

# TODO:
# Replace with custom icon
func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")


func _exit_tree():
	timeline_editor.queue_free()


func _init() -> void:
	timeline_editor = TimelineEditor.new()
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
