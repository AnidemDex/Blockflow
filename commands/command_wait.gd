@tool
extends Command

@export var wait_time:float:
	set(value):
		wait_time = value
		emit_changed()
	get: return wait_time


func _execution_steps() -> void:
	command_started.emit()
	var timer:SceneTreeTimer = command_manager.get_tree().create_timer(wait_time)
	timer.timeout.connect( emit_signal.bind("command_finished") )


func _get_name() -> String:
	return "Wait"


func _get_hint() -> String:
	var hint_str = String.num(wait_time, 4) + " second"
	# pluralize if we're not at '1 second'
	if wait_time != 1:
		hint_str += "s"
	return hint_str


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/timer.svg")
