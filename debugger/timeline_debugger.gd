extends Node

const TimelineDisplayer = preload("res://addons/blockflow/editor/timeline_displayer.gd")
const CommandManager = preload("res://addons/blockflow/command_manager.gd")

## Command manager node
var cm_manager:CommandManager
var timeline:Timeline

# Suggestion:
# in the future, you can export nodepaths in case the structure starts changing.
@onready var timeline_displayer:TimelineDisplayer = $Control/VBoxContainer/TimelineDisplayer
@onready var timeline_label:Label = $Control/VBoxContainer/InformationPanel/HBoxContainer/TimelineName
@onready var curr_command_label:Label = $Control/VBoxContainer/InformationPanel/HBoxContainer/CurrentCommand
@onready var cm_status_label:Label = $Control/VBoxContainer/InformationPanel/HBoxContainer/CommandManagerStatus

func _ready() -> void:
	_clear_information()
	
	## Debug stuff. Hide for real usage.
	#cm_manager = CommandManager.new()
	#cm_manager.timeline = load("res://timeline_with_all_commands.tres")
	#cm_manager.command_started.connect(_on_command_started)
	#cm_manager.command_finished.connect(_on_command_finished)
	#add_child(cm_manager)
	#debug(cm_manager)


func debug(command_manager:CommandManager) -> void:
	if not command_manager:
		return
	cm_manager = command_manager
	timeline = command_manager.timeline
	timeline_displayer.load_timeline(timeline)
	timeline_label.text = timeline.resource_path
	set_process(true)

func _process(delta: float) -> void:
	curr_command_label.text = str(cm_manager.current_command) + " " + str(cm_manager.current_command_idx)
	cm_status_label.text


func _clear_information() -> void:
	cm_manager = null
	timeline = null
	timeline_label.text = ""
	curr_command_label.text = ""
	cm_status_label.text = ""
	set_process(false)

func _on_command_started(command:Command) -> void:
	prints("Started:",command)
	var cmd_idx = timeline.get_command_idx(command)
	var tree_item = timeline_displayer.get_root().get_child(cmd_idx)
	timeline_displayer.set_selected(tree_item, 0)

func _on_command_finished(command:Command) -> void:
	prints("Finished:",command)


func _on_prev_button_pressed() -> void:
	pass # Replace with function body.


func _on_next_button_pressed() -> void:
	if not is_instance_valid(cm_manager):
		return
	
	cm_manager.go_to_next_command()


func _on_play_button_pressed() -> void:
	if not is_instance_valid(cm_manager):
		return
	
	cm_manager.start_timeline()
