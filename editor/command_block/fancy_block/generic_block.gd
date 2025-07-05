@tool
extends "res://addons/blockflow/editor/command_block/fancy_block/block.gd"

@onready var label_hint:Label = get_node_or_null(^"0/LabelHint") as Label
@onready var btn_collapse:Button = get_node_or_null(^"1/BtnCollapse") as Button
@onready var btn_tag:Button = get_node_or_null(^"Tag/BtnTag") as Button

func _update_block() -> void:
	if is_instance_valid(label_hint):
		label_hint.text = command.command_hint
	
	if is_instance_valid(btn_collapse):
		_update_toggle_icon()
		btn_collapse.visible = not command.collection.is_empty()
	
	if is_instance_valid(btn_tag):
		btn_tag.visible = not command.bookmark.is_empty()
		btn_tag.tooltip_text = command.bookmark

func _update_toggle_icon() -> void:
	if btn_collapse.button_pressed:
		btn_collapse.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	else:
		btn_collapse.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not command: return
		
		for subcommand in command.collection:
			if is_instance_valid(subcommand.editor_block):
				subcommand.editor_block.visible = visible

func _on_btn_collapse_toggled(toggled_on: bool) -> void:
	_update_toggle_icon()
	for subcommand in command.collection:
		if is_instance_valid(subcommand.editor_block):
			subcommand.editor_block.visible = not toggled_on
