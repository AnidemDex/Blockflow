@tool
extends HFlowContainer

const FALLBACK_ICON = preload("res://icon.svg")
const Settings = preload("res://addons/blockflow/blockflow.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

var command_button_list_pressed:Callable

func build_command_list() -> void:
	var default_commands:Array = Settings.DEFAULT_COMMAND_PATHS.duplicate()
	var custom_commands:Array = ProjectSettings.get_setting(
		Settings.PROJECT_SETTING_CUSTOM_COMMANDS, [])
	
	if default_commands.is_empty():
		push_error("CommandList: Can't create command list. Default commands are not defined!")
	
	default_commands.append_array(custom_commands)
	
	for child in get_children():
		child.queue_free()
	
	var commands:Array[Script]
	for command_path in default_commands:
		if typeof(command_path) != TYPE_STRING: continue # Somehow is not an string
		if command_path.is_empty(): continue
		if not ResourceLoader.exists(command_path, "Script"): continue
		
		var command_script:Script = load(command_path) as Script
		if not command_script:
			push_warning("CommandList: Resource at '%s' is not an Script."%command_path)
			continue
		commands.append(command_script)
	
	for command_script in commands:
		var command:CommandClass = command_script.new() as CommandClass
		if not command:
			push_error("CommandList: Can't create a command from '%s'."%command_script.resource_path)
			continue
		
		var button:Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set_custom_minimum_size(Vector2(160, 0))
		button.text = command.command_name

		var command_icon:Texture = command.command_icon
		if not command_icon:
			command_icon = FALLBACK_ICON
		button.expand_icon = true
		button.icon = command_icon
		button.set_drag_forwarding(
			command_button_get_drag_data.bind(command_script),
			Callable(),
			Callable()
		)

		add_child(button)
		
		if command_button_list_pressed.is_valid():
			button.pressed.connect(command_button_list_pressed.bind(command_script))

func command_button_get_drag_data(at_position:Vector2, command_script:Script):
	if not command_script: return
	
	var drag_data = {&"type":"resource", &"resource":null, &"from":self}
	drag_data.resource = command_script.new()
	
	var drag_preview = Button.new()
	drag_preview.text = (drag_data.resource as Command).command_name
	set_drag_preview(drag_preview)
	
	return drag_data
