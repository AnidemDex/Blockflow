# Command
Command is a Collection derivation, containing information about what the processor should do when it reach that command.

Each command defines its own behavior and should notify the processor when it ends or what should be the next step that it should take.

To create a custom command, just extend from `Command`, define a name, its behavior and finally register it to `CommandRecord`.

```gdscript
@tool # <- It MUST be tool or editor will not be able to use it.
extends Command

func _execution_steps() -> void:
	## Always notify that your command started. You have total control on
	## where to emit this signal, but be sure to emit it once.
	command_started.emit() # Notify that your command started
	
	## Implement your command behavior
	print("Hello")
	
	## Never forget to notify that you command have finished in order
	## to let the command manager know that is safe to continue to
	## the next event.
	go_to_next_command()

## Here you define your command name
func _get_name() -> StringName:
	return "CUSTOM_COMMAND"

## You can define other properties of the command,
## Editor will use those to change the command block appeareance.
func _get_icon() -> Texture:
	return load("res://icon.svg")
```