extends Command

@export var label:String
@export_multiline var description:String

func _get_command_name() -> String:
	return "Label"
