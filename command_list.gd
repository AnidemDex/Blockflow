@tool
extends VBoxContainer

const FALLBACK_ICON = preload("res://addons/blockflow/icons/false.svg")
const Settings = preload("res://addons/blockflow/blockflow.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

var command_button_list_pressed:Callable
var scroll_container:ScrollContainer
var command_container:VBoxContainer

func _ready():
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Commands"
	add_child(title)
	
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = scroll_container.SCROLL_MODE_DISABLED
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)
	
	command_container = VBoxContainer.new()
	command_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(command_container)


func build_command_list() -> void:
	var all_commands:Array = Settings.DEFAULT_COMMAND_PATHS.duplicate()
	var custom_commands:Array = ProjectSettings.get_setting(
		Settings.PROJECT_SETTING_CUSTOM_COMMANDS, [])
	
	if all_commands.is_empty():
		push_error("CommandList: Can't create command list. Default commands are not defined!")
	
	all_commands.append_array(custom_commands)
	
	for child in command_container.get_children():
		child.queue_free()
	
	var commands:Array[Script]
	for command_path in all_commands:
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

		command_container.add_child(button)
		
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
