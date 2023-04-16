@tool
extends Command

@export_multiline var comment:String:
	set(value):
		comment = value
		emit_changed()
	get:
		return comment

func _get_name() -> String:
	return "Comment"


func _get_hint() -> String:
	return "# " + comment


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/comment.svg")
