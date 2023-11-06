@tool
extends "res://addons/blockflow/commands/command.gd"

enum Wait {
	TIMEOUT,
	SIGNAL,
}

@export var wait_for:Wait = Wait.TIMEOUT:
	set(value):
		wait_for = value
		emit_changed()
		notify_property_list_changed()
	get: return wait_for

var wait_time:float:
	set(value):
		wait_time = value
		emit_changed()
	get: return wait_time

var signal_name:String:
	set(value):
		signal_name = value
		emit_changed()
	get: return signal_name


func _execution_steps() -> void:
	match wait_for:
		Wait.TIMEOUT:
			command_started.emit()
			var timer:SceneTreeTimer = command_manager.get_tree().create_timer(wait_time)
			timer.timeout.connect( go_to_next_command, CONNECT_ONE_SHOT )
		Wait.SIGNAL:
			if signal_name.is_empty():
				push_error("[Wait Command]: Signal name is empty.")
				return
			if is_instance_valid(target_node):
				if target_node.has_signal(signal_name):
					await Signal(target_node, signal_name)
					go_to_next_command()
					return
				push_error("[Wait Command]: target_node doesn't have '%s' signal."%signal_name)


func _get_name() -> StringName:
	return "Wait"


func _get_hint() -> String:
	var hint_str:String
	match wait_for:
		Wait.TIMEOUT:
			hint_str = String.num(wait_time, 4) + " second"
			# pluralize if we're not at '1 second'
			if wait_time != 1:
				hint_str += "s"
		
		Wait.SIGNAL:
			hint_str = "until '%s.%s' is emmited"%[target,signal_name]
	
	return hint_str


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/timer.svg")

func _get_property_list() -> Array:
	var p := []
	match wait_for:
		Wait.TIMEOUT:
			p.append({
				"name":"wait_time",
				"type":TYPE_FLOAT,
				"usage":PROPERTY_USAGE_DEFAULT,
				})
		Wait.SIGNAL:
			p.append({
				"name":"signal_name",
				"type":TYPE_STRING,
				"usage":PROPERTY_USAGE_DEFAULT,
				})
	return p
