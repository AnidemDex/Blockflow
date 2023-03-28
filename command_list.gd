extends HFlowContainer

# TODO
# This list can be a dynamic one to load custom made ones.
var scripts:Array[Script] = [
	load("res://addons/blockflow/commands/command_call.gd") as Script,
	load("res://addons/blockflow/commands/command_animate.gd") as Script,
	load("res://addons/blockflow/commands/command_comment.gd") as Script,
	load("res://addons/blockflow/commands/command_condition.gd") as Script,
	load("res://addons/blockflow/commands/command_goto.gd") as Script,
	load("res://addons/blockflow/commands/command_return.gd") as Script,
	load("res://addons/blockflow/commands/command_set.gd") as Script,
	load("res://addons/blockflow/commands/command_wait.gd") as Script,
	]

var command_button_list_pressed:Callable

func _ready() -> void:
	for command_script in scripts:
		var command:Command = command_script.new()
		var button:Button = Button.new()
		button.text = command.get_command_name()
		add_child(button)
		
		if command_button_list_pressed.is_valid():
			button.pressed.connect(command_button_list_pressed.bind(command_script))
