extends Control

# TODO: remove @onready
@onready var editor = $Editor

var timeline = load("res://addons/blockflow/editor/playground/timeline_with_all_commands.tres")
func _ready() -> void:
	timeline.resource_name = "Test timeline"
	editor.edit_timeline(timeline)

func _process(delta: float) -> void:
	$Toolbar/Do.disabled = !(editor.undo_redo as UndoRedo).has_redo()
	$Toolbar/Undo.disabled = !(editor.undo_redo as UndoRedo).has_undo()

func _on_do_pressed() -> void:
	(editor.undo_redo as UndoRedo).redo()


func _on_undo_pressed() -> void:
	(editor.undo_redo as UndoRedo).undo()
