@tool
extends Command

@export var animation:String = ""
@export var play_backwards:bool = false
@export var wait_until_animation_ends:bool = false

func _execution_steps() -> void:
	command_started.emit()
	
	var animation_player:AnimationPlayer = (target_node as AnimationPlayer)
	
	if animation_player == null:
		push_error("AnimationCommand: Can't animate an object that is not AnimationPlayer")
		command_finished.emit()
		return
	
	if animation.is_empty():
		push_error("AnimationCommand: 'animation' can't be empty")
		command_finished.emit()
		return
	
	if wait_until_animation_ends:
		animation_player.animation_finished.connect(
			Callable(self, "emit_signal").bind("command_finished"),
			CONNECT_ONE_SHOT
			)
	
	if play_backwards:
		(target_node as AnimationPlayer).play_backwards(animation)
	else:
		(target_node as AnimationPlayer).play(animation)
	
	if not wait_until_animation_ends:
		command_finished.emit()


func _get_name() -> String:
	return "Animate"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/animation.svg")
