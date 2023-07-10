@tool
extends TreeItem

const EditorCommand = preload("res://addons/blockflow/editor/editor_command/editor_command.gd")

var label:String = "" : 
	set(value):
		label = value
		set_text(EditorCommand.ColumnPosition.NAME_COLUMN, value)

var subcommand_quantity:int = 0
var subcommands:Array = [] :
	set(value):
		subcommands = value
		
		for command_idx in subcommands.size():
			var itm:TreeItem = create_child()
			itm.set_script(EditorCommand)
			var item:EditorCommand = itm as EditorCommand
			var command:Command = subcommands[command_idx] as Command
			
			if not command:
				assert(command)
				return
			
			item.command = command
		
		call_recursive.bind("update").call_deferred()

func _init():
	custom_minimum_height = 32
