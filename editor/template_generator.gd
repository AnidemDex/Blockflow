@tool
extends ConfirmationDialog

## TemplateGenerator node
## Creates a template resource according a passed command, saves it
## under templates folder and registers it in CommandRecord.

const PREVIEW_DESCRIPTION = "Saving command '{command_name}' with the following structure:"
const PATH_DESCRIPTION = "Template will be saved under path:"
const NOTE_DESCRIPTION = "Note: This template will be added to CommandRecord after save."

const CommandRecord = preload("res://addons/blockflow/core/command_record.gd")

var preview_desc_label:Label
var path_line_edit:LineEdit
var warning_label:Button

var _editor_file_dialog
var _file_dialog

var current_command
var template
var template_path


func create_from(command:Resource) -> void:
	_clean()
	current_command = command
	preview_desc_label.text = PREVIEW_DESCRIPTION.format({"command_name":command.command_name})
	popup_centered_ratio(0.4)

func _confirm() -> void:
	_create_template()
	_save_template()
	_register_template()

func _create_template() -> void:
	if not current_command:
		push_error("Failed to create a template: No command given")
		return
	
	template = current_command.get_duplicated()
	template_path = path_line_edit.text

func _save_template() -> void:
	if not template:
		push_error("Failed saving template: No template was created")
		return
	
	template.resource_path = template_path
	var error := ResourceSaver.save(template, template_path)
	
	if error != OK:
		push_error("Failed saving template: %s"%error_string(error))

func _register_template() -> void:
	var record:CommandRecord = CommandRecord.get_record()
	record.register(template, false)

func _clean() -> void:
	path_line_edit.text_changed.emit("")
	path_line_edit.text = ""
	get_ok_button().disabled = true

func _open_button_clicked() -> void:
	var __file_dialog := _get_file_dialog()
	__file_dialog.current_dir = ""
	__file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	__file_dialog.filters = ["*.tres, *.res ; Resource file"]
	__file_dialog.title = "Save Template"
	__file_dialog.popup_centered_ratio(0.5)

func _editor_file_dialog_file_selected(path:String) -> void:
	path_line_edit.text_changed.emit(path)
	path_line_edit.text = path

func _path_line_edit_text_changed(new_string:String) -> void:
	if not new_string.is_absolute_path():
		warning_label.text = "Not valid path."
		get_ok_button().disabled = true
		return
	
	if ResourceLoader.exists(new_string):
		warning_label.text = "A resource exists at the given path."
	else:
		warning_label.text = ""
	
	get_ok_button().disabled = false

func _get_file_dialog() -> ConfirmationDialog:
	if Engine.is_editor_hint():
		return _editor_file_dialog
	return _file_dialog

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			_clean()
			
			if not visible:
				current_command = null

func _init() -> void:
	unresizable = true
	popup_window = true
	get_ok_button().pressed.connect(_confirm)
	
	var p_bg := PanelContainer.new()
	p_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(p_bg, false, Node.INTERNAL_MODE_BACK)
	
	var main_vb := VBoxContainer.new()
	p_bg.add_child(main_vb, false, Node.INTERNAL_MODE_BACK)
	
	var preview_vb := VBoxContainer.new()
	main_vb.add_child(preview_vb, false, Node.INTERNAL_MODE_BACK)
	
	preview_desc_label = Label.new()
	preview_desc_label.text = PREVIEW_DESCRIPTION
	preview_vb.add_child(preview_desc_label, false, Node.INTERNAL_MODE_BACK)
	
	var collection_displayer := Tree.new()
	collection_displayer.custom_minimum_size = Vector2i(256, 128)
	preview_vb.add_child(collection_displayer, false, Node.INTERNAL_MODE_BACK)
	
	var separator := HSeparator.new()
	main_vb.add_child(separator, false, Node.INTERNAL_MODE_BACK)
	
	var path_vb := VBoxContainer.new()
	path_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(path_vb, false, Node.INTERNAL_MODE_BACK)
	
	var path_desc := Label.new()
	path_desc.text = PATH_DESCRIPTION
	path_vb.add_child(path_desc, false, Node.INTERNAL_MODE_BACK)
	
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_vb.add_child(hb, false, Node.INTERNAL_MODE_BACK)
	
	path_line_edit = LineEdit.new()
	path_line_edit.placeholder_text = "res://"
	path_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_line_edit.text_changed.connect(_path_line_edit_text_changed)
	hb.add_child(path_line_edit, false, Node.INTERNAL_MODE_BACK)
	
	var open_btn := Button.new()
	open_btn.text = "Select..."
	open_btn.pressed.connect(_open_button_clicked)
	hb.add_child(open_btn, false, Node.INTERNAL_MODE_BACK)
	
	warning_label = Button.new()
	warning_label.text = ""
	warning_label.disabled = true
	warning_label.focus_mode = Control.FOCUS_NONE
	path_vb.add_child(warning_label, false, Node.INTERNAL_MODE_BACK)
	
	var note_label := Label.new()
	note_label.text = NOTE_DESCRIPTION
	note_label.size_flags_vertical = Control.SIZE_SHRINK_END
	main_vb.add_child(note_label, false, Node.INTERNAL_MODE_BACK)
	
	if Engine.is_editor_hint():
# https://github.com/godotengine/godot/issues/73525#issuecomment-1606067249
		_editor_file_dialog = (EditorFileDialog as Variant).new()
		_editor_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_editor_file_dialog)
	else:
		_file_dialog = FileDialog.new()
		_file_dialog.file_selected.connect(_editor_file_dialog_file_selected)
		add_child(_file_dialog)
