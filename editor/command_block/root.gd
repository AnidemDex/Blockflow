@tool
extends "res://addons/blockflow/editor/command_block/block.gd"

const TimelineClass = preload("res://addons/blockflow/command_collection.gd")
const ICON = preload("res://addons/blockflow/icons/timeline.svg")

var timeline:TimelineClass:set = set_timeline

func update() -> void:
	var timeline_name:String = timeline.resource_name
	if timeline_name.is_empty():
		timeline_name = timeline.resource_path.get_file()
	
	for i in get_tree().columns:
		set_expand_right(i, false)
		set_icon_max_width(i, 32)
	
	set_text(ColumnPosition.NAME_COLUMN, timeline_name)
	set_text_alignment(ColumnPosition.NAME_COLUMN, HORIZONTAL_ALIGNMENT_LEFT)
	set_text(ColumnPosition.LAST_COLUMN, str(timeline.get_command_count()))
	set_icon(0, ICON)
	

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
	update()

func set_command(_value) -> void:
	command = null
	push_error("Can't assign a command to root item!")

func _init():
	disable_folding = true
	custom_minimum_height = 32
