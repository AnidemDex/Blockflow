@tool
extends Command

@export var showname:String = "":
	set(value):
		showname = value
		emit_changed()
	get:
		return showname
@export_multiline var dialog:String:
	set(value):
		dialog = value
		emit_changed()
	get:
		return dialog
@export var additive:bool = false:
	set(value):
		additive = value
		emit_changed()
	get:
		return additive
@export_range(0, 10.0) var letter_delay:float = 0.02:
	set(value):
		letter_delay = value
		emit_changed()
	get:
		return letter_delay
@export var wait_until_finished:bool = true:
	set(value):
		wait_until_finished = value
		emit_changed()
	get:
		return wait_until_finished
@export var speaking_character:String = "":
	set(value):
		speaking_character = value
		emit_changed()
	get:
		return speaking_character
@export var bump_speaker:bool = false:
	set(value):
		bump_speaker = value
		emit_changed()
	get:
		return bump_speaker
@export var highlight_speaker:bool = false:
	set(value):
		highlight_speaker = value
		emit_changed()
	get:
		return highlight_speaker
@export var set_z_index:int = 0:
	set(value):
		set_z_index = value
		emit_changed()
	get:
		return set_z_index

func _execution_steps() -> void:
	command_started.emit()
	
	target_node.dialog(showname, dialog, additive, letter_delay)
	if speaking_character:
		var speaker = target_node.get_character(speaking_character)
		if speaker:
			if bump_speaker:
				speaker.bump()
			for chara in target_node.characters.get_children():
				if not highlight_speaker or chara == speaker:
					chara.blackout(false, 0.25)
				else:
					chara.blackout(true, 0.25)
			speaker.z_index = set_z_index
			speaker.start_talking()
			if target_node.is_connected("dialog_finished", speaker.stop_talking):
				target_node.dialog_finished.disconnect(speaker.stop_talking)
			target_node.dialog_finished.connect(speaker.stop_talking, CONNECT_ONE_SHOT)
	if wait_until_finished:
		if target_node.is_connected("dialog_finished", dialog_finished):
			target_node.dialog_finished.disconnect(dialog_finished)
		target_node.dialog_finished.connect(
			dialog_finished,
			CONNECT_ONE_SHOT
			)
	else:
		command_finished.emit()

func dialog_finished():
	command_finished.emit()

func _get_name() -> String:
	var prefix = ""
	if bump_speaker:
		prefix = "^"
	return (prefix + showname) if showname else "Dialog"


func _get_hint() -> String:
	return dialog


func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/speech.svg")


# stop at end by default
func _property_can_revert(property: StringName) -> bool:
	if property == "continue_at_end":
		return true
	return false

func _property_get_revert(property: StringName):
	if property == "continue_at_end":
		return false
	return null

func _init() -> void:
	super()
	continue_at_end = false
