@tool
extends "res://addons/blockflow/editor/editor_command/editor_command.gd"

var label:String = "" : 
	set(value):
		label = value
		set_text(ColumnPosition.NAME_COLUMN, value)

var subcommand_quantity:int = 0
var subcommands:Array = [] :
	set(value):
		subcommands = value

func update() -> void:
	return

func _init():
	custom_minimum_height = 32
