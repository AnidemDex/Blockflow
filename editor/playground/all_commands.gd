extends Node

var timeline:Timeline = load("res://addons/blockflow/editor/playground/timeline_with_all_commands.tres")
@onready var cm = $CommandManager
@onready var tm_debugger = $Window/TimelineDebugger

var all_ready:bool = false

func _ready() -> void:
	cm.timeline = timeline
	tm_debugger.debug(cm)
	all_ready = true



func _set(property: StringName, value) -> bool:
	if all_ready:
		printt("Watcher -> Set:", property, value)
	return false
