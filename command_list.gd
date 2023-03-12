extends HFlowContainer

# TODO: This should be replaced with a generation
# made from reading scripts from specific folder
@export var scripts:Array[Script] = []

# Editor should define who is it.
@export var editor:Node

func _ready() -> void:
	for command_script in scripts:
		var command:Command = command_script.new()
		var button = Button.new()
		add_child(button)
		button.text = command.get_command_name()
		
		button.pressed.connect(editor.command_button_list_pressed.bind(command_script))
