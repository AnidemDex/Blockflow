@tool
extends EditorPlugin

const TimelineEditor = preload("res://addons/blockflow/editor/editor.gd")

var timeline_editor:TimelineEditor
var last_edited_timeline:Timeline
var last_handled_object:Object

func _enter_tree():
	get_editor_interface().get_editor_main_screen().add_child(timeline_editor)
	_make_visible(false)


func _handles(object: Object) -> bool:
	var o:Resource = object as Resource
	if not o: return false
	var condition:bool = false
	condition = is_instance_of(object, Timeline) or is_instance_of(object, Command)
	
	last_handled_object = object
	
	return condition


func _edit(object: Object) -> void:
	if last_edited_timeline == object:
		return
	
	if object is Timeline:
		timeline_editor.editor_undoredo = get_undo_redo()
		timeline_editor.edit_timeline(object as Timeline)
		last_edited_timeline = object


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
	timeline_editor.edit_callback = Callable(get_editor_interface(), "edit_resource")
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
