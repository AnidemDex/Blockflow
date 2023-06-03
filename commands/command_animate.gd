@tool
extends Command

@export var animation:String = "":
	set(value):
		animation = value
		emit_changed()
	get:
		return animation
@export_range(-1, 1) var custom_blend:float = -1:
	set(value):
		custom_blend = value
		emit_changed()
	get:
		return custom_blend
@export_range(0.0001, 1000.0) var custom_speed:float = 1.0:
	set(value):
		custom_speed = value
		emit_changed()
	get:
		return custom_speed
@export var play_backwards:bool = false:
	set(value):
		play_backwards = value
		emit_changed()
	get:
		return play_backwards
@export var wait_until_animation_ends:bool = false:
	set(value):
		wait_until_animation_ends = value
		emit_changed()
	get:
		return wait_until_animation_ends


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

	(target_node as AnimationPlayer).play(animation,
		custom_blend,
		(-custom_speed if play_backwards else custom_speed),
		play_backwards
		)
	
	if not wait_until_animation_ends:
		command_finished.emit()


func _get_name() -> String:
	return "Animate"


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/animation.svg")


func _get_hint() -> String:
	var hint_str = "play '" + animation + "'"
	if play_backwards:
		hint_str += " backwards"
	if wait_until_animation_ends:
		hint_str += " and wait"
	if target != NodePath():
		hint_str += " on " + str(target)
	return hint_str
