# meta-name: Command
# meta-description: Empty command template
# meta-default: true
extends Command

func _execution_steps() -> void:
	## Always notify that your command started. You have total control on
	## where to emit this signal, but be sure to emit it once.
	command_started.emit() # Notify that your command started
	
	## Implement your command execution in this space
	#print("Hello")
	
	## Never forget to notify that you command have finished in order
	## to let the command manager know that is safe to continue to
	## the next event.
	go_to_next_command()


func _get_name() -> StringName:
	return "CUSTOM_COMMAND"


func _get_icon() -> Texture:
	return load("res://icon.svg")
