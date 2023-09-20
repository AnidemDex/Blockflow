extends Command

## A Command Specifically designed to hold commands.
##
## Usually used as branch, a group command does nothing internally.

## Group name. This name will be used in editor
## instead of [member command_name].
@export var group_name:String

func _get_name() -> StringName: return group_name

func _can_hold_commands() -> bool: return true
