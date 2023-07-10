@tool
extends "res://addons/blockflow/editor/editor_command/editor_command.gd"

const TimelineClass = preload("res://addons/blockflow/timeline.gd")

var timeline:TimelineClass:set = set_timeline

func update() -> void:
	var commands:Array = timeline.commands
	var timeline_name:String = timeline.resource_name
	if timeline_name.is_empty():
		timeline_name = timeline.resource_path.get_file()
	
	for i in get_tree().columns:
		set_expand_right(i, false)
	
	set_text(ColumnPosition.NAME_COLUMN, timeline_name)
	set_text_alignment(ColumnPosition.NAME_COLUMN, HORIZONTAL_ALIGNMENT_LEFT)
	set_text(ColumnPosition.LAST_COLUMN, str(commands.size()))
	

func set_timeline(value:TimelineClass) -> void:
	if value == timeline:
		return
	
	if timeline and timeline.changed.is_connected(update):
		timeline.changed.disconnect(update)
	
	timeline = value
	set_metadata(0, timeline)
	
	if not timeline:
		return
	
	timeline.changed.connect(update)

func set_command(_value) -> void:
	command = null
	push_error("Can't assign a command to root item!")

func _init():
	disable_folding = true
	custom_minimum_height = 32
