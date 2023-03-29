extends Command

@export_multiline var comment:String

func _get_command_name() -> String:
	return "Comment"


func _get_command_desc() -> String:
	return "# Comment Here"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/comment.svg")


func _get_command_desc_icon() -> Texture:
	return load("res://addons/blockflow/icons/bookmark.svg")
