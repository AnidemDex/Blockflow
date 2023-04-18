@tool
extends Command

@export var wait_time:float

func _execution_steps() -> void:
	command_started.emit()
	var timer:SceneTreeTimer = command_manager.get_tree().create_timer(wait_time)
	timer.timeout.connect( emit_signal.bind("command_finished") )


func _get_name() -> String:
	return "Wait"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/Timer.svg")
