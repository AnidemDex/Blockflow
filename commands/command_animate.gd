extends Command

func _execution_steps(manager) -> void:
	pass


func _get_command_name() -> String:
	return "Animate"


func _get_command_desc() -> String:
	return "play/stop/etc. Bababooey on Player/AnimationPlayer"


func _get_command_icon() -> Texture:
	return load("res://addons/blockflow/icons/animation.svg")
